import os
import sys
import random
import datetime as dt
from typing import List, Dict, Any, Optional, Tuple

# Make utils importable
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from utils import get_db_connection, load_ids


# --- Config ---
ORDERS_PER_USER_MIN = int(os.getenv('ORDERS_PER_USER_MIN', '1'))
ORDERS_PER_USER_MAX = int(os.getenv('ORDERS_PER_USER_MAX', '4'))
MAX_ITEMS_PER_ORDER = int(os.getenv('MAX_ITEMS_PER_ORDER', '5'))
PAYMENT_FAIL_RATE = float(os.getenv('PAYMENT_FAIL_RATE', '0.06'))
ORDER_CANCEL_RATE = float(os.getenv('ORDER_CANCEL_RATE', '0.05'))
ORDER_RETURN_RATE = float(os.getenv('ORDER_RETURN_RATE', '0.03'))
ORDER_REFUND_RATE = float(os.getenv('ORDER_REFUND_RATE', '0.02'))
REVIEW_RATE = float(os.getenv('REVIEW_RATE', '0.35'))  # share of purchased products to review
WISHLIST_ITEMS_PER_USER = int(os.getenv('WISHLIST_ITEMS_PER_USER', '5'))

DEFAULT_CURRENCY = os.getenv('CURRENCY', 'USD')[:3].upper() or 'USD'


def resolve_status_id(cur, table_name: str, status_key: str) -> Optional[int]:
    # Generic resolver for *_StatusTypes(status_KEY)
    q = f"SELECT status_ID FROM {table_name} WHERE status_KEY = :k"
    cur.execute(q, {'k': status_key})
    r = cur.fetchone()
    return int(r[0]) if r else None


def load_users() -> List[int]:
    try:
        users_raw = load_ids('users')
        return [int(u) for u in users_raw if isinstance(u, int) or str(u).isdigit()]
    except Exception:
        return []


def fetch_users_from_db(cur) -> List[int]:
    cur.execute("SELECT user_ID FROM Users")
    return [int(r[0]) for r in cur.fetchall()]


def fetch_active_products(cur) -> List[Tuple[int, float, int]]:
    # product_ID, product_PRICE, product_STOCK
    cur.execute(
        "SELECT product_ID, product_PRICE, NVL(product_STOCK,0) FROM Products WHERE NVL(is_active,1) = 1"
    )
    return [(int(pid), float(price), int(stock)) for pid, price, stock in cur.fetchall()]


def choose_items(products: List[Tuple[int, float, int]]) -> List[Tuple[int, float, int]]:
    # returns (product_ID, price, qty)
    if not products:
        return []
    count = random.randint(1, max(1, min(MAX_ITEMS_PER_ORDER, len(products))))
    picked = random.sample(products, k=count)
    items = []
    for pid, price, stock in picked:
        if stock <= 0:
            continue
        qty = random.randint(1, min(3, stock))
        items.append((pid, price, qty))
    return items


def adjust_stock(cur, items: List[Tuple[int, float, int]]):
    for pid, _price, qty in items:
        cur.execute("UPDATE Products SET product_STOCK = product_STOCK - :q WHERE product_ID = :p AND product_STOCK >= :q",
                    { 'q': qty, 'p': pid })


def sum_amount(items: List[Tuple[int, float, int]]) -> float:
    return round(sum(price * qty for _pid, price, qty in items), 2)


def simulate_order_flow(cur, user_id: int, status_ids: Dict[str, int], payment_status_ids: Dict[str, int], delivery_status_ids: Dict[str, int], products: List[Tuple[int, float, int]]):
    # Pick items
    items = choose_items(products)
    if not items:
        return None

    now = dt.datetime.utcnow()

    # Create Order (Cart -> Pending)
    order_id = None
    order_date = now - dt.timedelta(days=random.randint(0, 60))
    cur.execute(
        """
        INSERT INTO Orders (user_ID, order_DATE, order_STATUS_ID, order_AMOUNT, promo_SAVINGS)
        VALUES (:u, :d, :s, :a, :ps)
        RETURNING order_ID INTO :oid
        """,
        {
            'u': user_id,
            'd': order_date,
            's': status_ids.get('Cart'),
            'a': 0.0,
            'ps': 0.0,
            'oid': cur.var(int)
        }
    )
    order_id = int(cur.getimplicitresults()[0][0]) if cur.getimplicitresults() else int(cur.bindvars()['oid'].getvalue())

    # Fill delivery basic info
    address = f"{random.randint(10000,99999)}, City-{random.randint(1,999)}, Street-{random.randint(1,200)}, b.{random.randint(1,50)}"
    carrier = random.choice(['DHL', 'FedEx', 'UPS', 'USPS', 'Local'])
    tracking = f"TRK{random.randint(10000000,99999999)}"
    cur.execute(
        "UPDATE Orders SET delivery_ADDRESS = :addr, shipping_carrier_NAME = :car, tracking_NUMBER = :trk WHERE order_ID = :oid",
        {'addr': address, 'car': carrier, 'trk': tracking, 'oid': order_id}
    )

    # Add OrderItems and adjust stock
    oi_rows = []
    for pid, price, qty in items:
        oi_rows.append({'order_ID': order_id, 'product_ID': pid, 'quantity': qty, 'price': price})
    cur.executemany(
        "INSERT INTO OrderItems (order_ID, product_ID, quantity, price) VALUES (:order_ID, :product_ID, :quantity, :price)",
        oi_rows, batcherrors=False
    )
    adjust_stock(cur, items)

    # Compute order amount
    amount = sum_amount(items)
    cur.execute("UPDATE Orders SET order_AMOUNT = :a WHERE order_ID = :oid", {'a': amount, 'oid': order_id})

    # Payment
    payment_failed = random.random() < PAYMENT_FAIL_RATE
    pay_status = 'Failed' if payment_failed else 'Completed'
    pay_status_id = payment_status_ids.get('Failed') if payment_failed else payment_status_ids.get('Completed')
    cur.execute(
        """
        INSERT INTO Payments (order_ID, payment_DATE, payment_METHOD, payment_STATUS_ID, payment_AMOUNT, currency, transaction_ID)
        VALUES (:o, :d, :m, :s, :amt, :cur, :tx)
        """,
        {
            'o': order_id,
            'd': order_date + dt.timedelta(hours=1),
            'm': random.choice(['Card', 'PayPal', 'ApplePay', 'GooglePay']),
            's': pay_status_id,
            'amt': amount if not payment_failed else 0.0,
            'cur': DEFAULT_CURRENCY,
            'tx': f"TX{random.randint(1000000000, 9999999999)}"
        }
    )

    # Order/Delivery Status Progression
    cancelled = False
    returned = False
    refunded = False

    if payment_failed:
        # Stay Pending/Cart → Cancelled sometimes
        if random.random() < ORDER_CANCEL_RATE:
            cur.execute("UPDATE Orders SET order_STATUS_ID = :s WHERE order_ID = :oid", {'s': status_ids.get('Cancelled'), 'oid': order_id})
            cancelled = True
        else:
            cur.execute("UPDATE Orders SET order_STATUS_ID = :s WHERE order_ID = :oid", {'s': status_ids.get('Pending'), 'oid': order_id})
        return {'order_id': order_id, 'items': items, 'amount': amount, 'cancelled': cancelled}

    # Successful payment: progress through shipping
    cur.execute("UPDATE Orders SET order_STATUS_ID = :s WHERE order_ID = :oid", {'s': status_ids.get('Pending'), 'oid': order_id})
    cur.execute("UPDATE Orders SET order_STATUS_ID = :s WHERE order_ID = :oid", {'s': status_ids.get('Processing'), 'oid': order_id})

    # Delivery lifecycle
    shipped_date = order_date + dt.timedelta(days=random.randint(0, 2))
    in_transit_date = shipped_date + dt.timedelta(days=random.randint(1, 4))
    out_for_delivery_date = in_transit_date + dt.timedelta(days=1)
    delivered_date = out_for_delivery_date + dt.timedelta(days=1)

    cur.execute("UPDATE Orders SET shipped_DATE = :d, delivery_STATUS_ID = :s WHERE order_ID = :oid",
                {'d': shipped_date, 's': delivery_status_ids.get('Shipped'), 'oid': order_id})
    cur.execute("UPDATE Orders SET estimated_delivery_DATE = :d, delivery_STATUS_ID = :s WHERE order_ID = :oid",
                {'d': in_transit_date + dt.timedelta(days=2), 's': delivery_status_ids.get('InTransit'), 'oid': order_id})
    cur.execute("UPDATE Orders SET delivery_STATUS_ID = :s WHERE order_ID = :oid",
                {'s': delivery_status_ids.get('OutForDelivery'), 'oid': order_id})
    cur.execute("UPDATE Orders SET actual_delivery_DATE = :d, delivery_STATUS_ID = :s WHERE order_ID = :oid",
                {'d': delivered_date, 's': delivery_status_ids.get('Delivered'), 'oid': order_id})

    # Post-delivery outcomes: return/refund vs completed
    if random.random() < ORDER_RETURN_RATE:
        cur.execute("UPDATE Orders SET order_STATUS_ID = :s WHERE order_ID = :oid", {'s': status_ids.get('Returned'), 'oid': order_id})
        returned = True
        if random.random() < ORDER_REFUND_RATE:
            # Refund payment (create a separate refund record)
            cur.execute(
                "INSERT INTO Payments (order_ID, payment_DATE, payment_METHOD, payment_STATUS_ID, payment_AMOUNT, currency, transaction_ID) "
                "VALUES (:o, :d, :m, :s, :amt, :cur, :tx)",
                {
                    'o': order_id,
                    'd': delivered_date + dt.timedelta(days=2),
                    'm': 'Refund',
                    's': payment_status_ids.get('Refunded'),
                    'amt': amount,
                    'cur': DEFAULT_CURRENCY,
                    'tx': f"RF{random.randint(100000000, 999999999)}"
                }
            )
            cur.execute("UPDATE Orders SET order_STATUS_ID = :s WHERE order_ID = :oid", {'s': status_ids.get('Refunded'), 'oid': order_id})
            refunded = True
    else:
        cur.execute("UPDATE Orders SET order_STATUS_ID = :s WHERE order_ID = :oid", {'s': status_ids.get('Completed'), 'oid': order_id})

    return {
        'order_id': order_id,
        'items': items,
        'amount': amount,
        'returned': returned,
        'refunded': refunded,
    }


def insert_reviews(cur, user_id: int, purchased_products: List[int]):
    to_review = [pid for pid in purchased_products if random.random() < REVIEW_RATE]
    if not to_review:
        return
    # Avoid duplicates: check existing
    binds = {f'p{i}': pid for i, pid in enumerate(to_review)}
    bind_list = ','.join([f":p{i}" for i in range(len(to_review))])
    cur.execute(f"SELECT product_ID FROM Review WHERE user_ID = :u AND product_ID IN ({bind_list})", {**{'u': user_id}, **binds})
    existing = {int(r[0]) for r in cur.fetchall()}
    rows = []
    for pid in to_review:
        if pid in existing:
            continue
        rating = random.randint(3, 5)
        comment = random.choice([
            'Отличное качество и тихая работа.',
            'Соответствует описанию, быстрая доставка.',
            'Хорошая цена, рекомендую.',
            'В целом доволен покупкой.',
        ])
        rows.append({'user_ID': user_id, 'product_ID': pid, 'rew_RATING': rating, 'rew_COMMENT': comment, 'rew_DATE': dt.datetime.utcnow()})
    if rows:
        cur.executemany(
            "INSERT INTO Review (user_ID, product_ID, rew_RATING, rew_COMMENT, rew_DATE) "
            "VALUES (:user_ID, :product_ID, :rew_RATING, :rew_COMMENT, :rew_DATE)",
            rows, batcherrors=False
        )


def insert_wishlist(cur, user_id: int, candidates: List[int], already_bought: List[int]):
    left = [pid for pid in candidates if pid not in already_bought]
    if not left:
        return
    picks = random.sample(left, k=min(WISHLIST_ITEMS_PER_USER, len(left)))
    # Avoid duplicates in DB
    binds = {f'p{i}': pid for i, pid in enumerate(picks)}
    bind_list = ','.join([f":p{i}" for i in range(len(picks))])
    cur.execute(f"SELECT product_ID FROM Wishlist WHERE user_ID = :u AND product_ID IN ({bind_list})", {**{'u': user_id}, **binds})
    existing = {int(r[0]) for r in cur.fetchall()}
    rows = []
    for pid in picks:
        if pid in existing:
            continue
        rows.append({'user_ID': user_id, 'product_ID': pid, 'added_AT': dt.datetime.utcnow(), 'notes': None})
    if rows:
        cur.executemany(
            "INSERT INTO Wishlist (user_ID, product_ID, added_AT, notes) VALUES (:user_ID, :product_ID, :added_AT, :notes)",
            rows, batcherrors=False
        )


def main():
    print('--- Orders/Activity Data Generator ---')
    users = load_users()
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        if not users:
            users = fetch_users_from_db(cur)
        if not users:
            print('No users found. Run 01_populate_base_entities.py first.')
            return

        # Resolve status IDs
        status_keys = ['Cart', 'Pending', 'Processing', 'Shipped', 'InTransit', 'Delivered', 'Completed', 'Cancelled', 'Returned', 'Refunded']
        payment_keys = ['Pending', 'Processing', 'Completed', 'Failed', 'Refunded', 'PartiallyRefunded']
        delivery_keys = ['Preparing', 'Shipped', 'InTransit', 'OutForDelivery', 'Delivered', 'FailedAttempt', 'Returned']
        status_ids = {k: resolve_status_id(cur, 'OrderStatusTypes', k) for k in status_keys}
        payment_status_ids = {k: resolve_status_id(cur, 'PaymentStatusTypes', k) for k in payment_keys}
        delivery_status_ids = {k: resolve_status_id(cur, 'DeliveryStatusTypes', k) for k in delivery_keys}

        if any(v is None for v in status_ids.values()) or any(v is None for v in payment_status_ids.values()) or any(v is None for v in delivery_status_ids.values()):
            print('Status types missing. Ensure 02_reference_data.sql and 03_status_transitions.sql have been executed.')
            return

        # Products cache
        products = fetch_active_products(cur)
        if not products:
            print('No products available. Run product generators first.')
            return

        user_orders_info: Dict[int, List[int]] = {u: [] for u in users}  # user -> purchased product_IDs

        # Generate orders per user
        total_orders = 0
        for u in users:
            n_orders = random.randint(ORDERS_PER_USER_MIN, ORDERS_PER_USER_MAX)
            for _ in range(n_orders):
                try:
                    info = simulate_order_flow(cur, u, status_ids, payment_status_ids, delivery_status_ids, products)
                    if info and info.get('items'):
                        total_orders += 1
                        for pid, price, qty in info['items']:
                            user_orders_info[u].extend([pid] * qty)
                except Exception as e:
                    conn.rollback()
                    print(f"Error creating order for user {u}: {e}")
                else:
                    conn.commit()

        print(f"Created {total_orders} orders.")

        # Reviews and wishlists
        all_product_ids = [pid for pid, _price, _stock in products]
        for u in users:
            try:
                purchased = user_orders_info.get(u, [])
                insert_reviews(cur, u, list(set(purchased)))
                insert_wishlist(cur, u, all_product_ids, list(set(purchased)))
            except Exception as e:
                conn.rollback()
                print(f"Error creating activity (reviews/wishlist) for user {u}: {e}")
            else:
                conn.commit()

        print('--- Orders/Activity generation finished ---')

    finally:
        try:
            cur.close()
        except Exception:
            pass
        try:
            conn.close()
        except Exception:
            pass


if __name__ == '__main__':
    main()
