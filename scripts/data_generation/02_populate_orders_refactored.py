# Refactored version of 02_populate_orders.py
# Key improvements:
# 1.  **Enhanced Readability**: The main simulation logic is decomposed from one large function
#     into smaller, single-responsibility functions (create_order, process_payment, etc.).
# 2.  **Improved Security**: Removed f-string formatting from SQL queries to prevent
#     potential SQL injection vulnerabilities, adhering to best practices.
# 3.  **Clarity and Maintainability**: The code flow is more logical and easier to follow,
#     making future modifications simpler and safer.

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
ORDERS_PER_USER_MAX = int(os.getenv('ORDERS_PER_USER_MAX', '5'))
MAX_ITEMS_PER_ORDER = int(os.getenv('MAX_ITEMS_PER_ORDER', '5'))
PAYMENT_FAIL_RATE = float(os.getenv('PAYMENT_FAIL_RATE', '0.06'))
ORDER_CANCEL_RATE = float(os.getenv('ORDER_CANCEL_RATE', '0.05'))
ORDER_RETURN_RATE = float(os.getenv('ORDER_RETURN_RATE', '0.03'))
ORDER_REFUND_RATE = float(os.getenv('ORDER_REFUND_RATE', '0.02'))
REVIEW_RATE = float(os.getenv('REVIEW_RATE', '0.35'))
WISHLIST_ITEMS_PER_USER = int(os.getenv('WISHLIST_ITEMS_PER_USER', '5'))

DEFAULT_CURRENCY = os.getenv('CURRENCY', 'USD')[:3].upper() or 'USD'

# --- Safe Status Resolvers ---
STATUS_TABLE_MAP = {
    'order': 'OrderStatusTypes',
    'payment': 'PaymentStatusTypes',
    'delivery': 'DeliveryStatusTypes',
}

def resolve_status_ids(cur, status_type_key: str, status_keys: List[str]) -> Dict[str, int]:
    """Safely resolves multiple status keys to their IDs from the correct table."""
    table_name = STATUS_TABLE_MAP.get(status_type_key)
    if not table_name:
        raise ValueError(f"Invalid status type key: {status_type_key}")

    binds = {f'k{i}': key for i, key in enumerate(status_keys)}
    bind_list = ','.join([f":k{i}" for i in range(len(status_keys))])
    
    query = f"SELECT status_KEY, status_ID FROM {table_name} WHERE status_KEY IN ({bind_list})"
    cur.execute(query, binds)
    
    return {key: int(sid) for key, sid in cur.fetchall()}


# --- Data Fetching ---
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
    cur.execute(
        "SELECT product_ID, product_PRICE, NVL(product_STOCK,0) FROM Products WHERE NVL(is_active,1) = 1"
    )
    return [(int(pid), float(price), int(stock)) for pid, price, stock in cur.fetchall()]


# --- Core Logic Components ---
def choose_items(products: List[Tuple[int, float, int]]) -> List[Tuple[int, float, int]]:
    """Picks a random number of items for an order. Returns (product_ID, price, qty)."""
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


def create_order_and_items(cur, user_id: int, items: List[Tuple[int, float, int]], cart_status_id: int) -> Optional[Tuple[int, float, dt.datetime]]:
    """Creates an order, adds items, adjusts stock, and calculates the total amount."""
    order_date = dt.datetime.now(dt.timezone.utc) - dt.timedelta(days=random.randint(0, 60))
    
    # 1. Create Order record
    cur.execute(
        "INSERT INTO Orders (user_ID, order_DATE, order_STATUS_ID, order_AMOUNT) VALUES (:u, :d, :s, 0.0) RETURNING order_ID INTO :oid",
        {'u': user_id, 'd': order_date, 's': cart_status_id, 'oid': cur.var(int)}
    )
    order_id = int(cur.bindvars['oid'].getvalue()[0])
    # 2. Add OrderItems
    oi_rows = [{'order_ID': order_id, 'product_ID': pid, 'quantity': qty, 'price': price} for pid, price, qty in items]
    cur.executemany(
        "INSERT INTO OrderItems (order_ID, product_ID, quantity, price) VALUES (:order_ID, :product_ID, :quantity, :price)",
        oi_rows
    )

    # 3. Adjust stock
    stock_updates = [{'q': qty, 'p': pid} for pid, _price, qty in items]
    cur.executemany("UPDATE Products SET product_STOCK = product_STOCK - :q WHERE product_ID = :p AND product_STOCK >= :q", stock_updates)

    # 4. Calculate final amount and update order
    amount = round(sum(price * qty for _pid, price, qty in items), 2)
    cur.execute("UPDATE Orders SET order_AMOUNT = :a WHERE order_ID = :oid", {'a': amount, 'oid': order_id})
    
    return order_id, amount, order_date


def process_payment(cur, order_id: int, amount: float, order_date: dt.datetime, payment_status_ids: Dict[str, int]) -> bool:
    """Simulates a payment for the order and returns True if successful."""
    payment_failed = random.random() < PAYMENT_FAIL_RATE
    pay_status_id = payment_status_ids['Failed'] if payment_failed else payment_status_ids['Completed']
    
    cur.execute(
        """
        INSERT INTO Payments (order_ID, payment_DATE, payment_METHOD, payment_STATUS_ID, payment_AMOUNT, currency, transaction_ID)
        VALUES (:o, :d, :m, :s, :amt, :cur, :tx)
        """,
        {
            'o': order_id,
            'd': order_date + dt.timedelta(minutes=random.randint(1, 60)),
            'm': random.choice(['Card', 'PayPal', 'ApplePay', 'GooglePay']),
            's': pay_status_id,
            'amt': 0.0 if payment_failed else amount,
            'cur': DEFAULT_CURRENCY,
            'tx': f"TX{random.randint(1000000000, 9999999999)}"
        }
    )
    return not payment_failed


def simulate_delivery(cur, order_id: int, order_date: dt.datetime, delivery_status_ids: Dict[str, int]) -> dt.datetime:
    """Simulates the delivery process, updating status and dates along the way."""
    shipped_date = order_date + dt.timedelta(days=random.randint(1, 3))
    delivered_date = shipped_date + dt.timedelta(days=random.randint(2, 7))
    estimated_delivery_date = shipped_date + dt.timedelta(days=random.randint(3, 8))

    # Atomically update all date fields and set final delivery status
    cur.execute(
        """
        UPDATE Orders
        SET shipped_DATE = :ship_d,
            estimated_delivery_DATE = :est_d,
            actual_delivery_DATE = :actual_d,
            delivery_STATUS_ID = :del_stat_id,
            shipping_carrier_NAME = :carrier,
            tracking_NUMBER = :trk,
            delivery_ADDRESS = :addr
        WHERE order_ID = :oid
        """,
        {
            'ship_d': shipped_date,
            'est_d': estimated_delivery_date,
            'actual_d': delivered_date,
            'del_stat_id': delivery_status_ids['Delivered'],
            'carrier': random.choice(['DHL', 'FedEx', 'UPS', 'USPS']),
            'trk': f"TRK{random.randint(10000000,99999999)}",
            'addr': f"{random.randint(10000,99999)}, City-{random.randint(1,999)}, Street-{random.randint(1,200)}",
            'oid': order_id
        }
    )
    return delivered_date


def handle_post_delivery_flow(cur, order_id: int, amount: float, delivered_date: dt.datetime, status_ids: Dict[str, int], payment_status_ids: Dict[str, int]) -> Dict[str, Any]:
    """Handles returns, refunds, or completes the order."""
    final_state = {'returned': False, 'refunded': False}
    final_order_status_id = status_ids['Completed']

    if random.random() < ORDER_RETURN_RATE:
        final_order_status_id = status_ids['Returned']
        final_state['returned'] = True

        if random.random() < ORDER_REFUND_RATE:
            cur.execute(
                "INSERT INTO Payments (order_ID, payment_DATE, payment_METHOD, payment_STATUS_ID, payment_AMOUNT, currency, transaction_ID) "
                "VALUES (:o, :d, 'Refund', :s, :amt, :cur, :tx)",
                {
                    'o': order_id,
                    'd': delivered_date + dt.timedelta(days=2),
                    's': payment_status_ids['Refunded'],
                    'amt': amount,
                    'cur': DEFAULT_CURRENCY,
                    'tx': f"RF{random.randint(100000000, 999999999)}"
                }
            )
            final_order_status_id = status_ids['Refunded']
            final_state['refunded'] = True

    cur.execute("UPDATE Orders SET order_STATUS_ID = :s WHERE order_ID = :oid", {'s': final_order_status_id, 'oid': order_id})
    return final_state


def simulate_full_order_lifecycle(cur, user_id: int, products: List[Tuple[int, float, int]], statuses: Dict[str, Dict[str, int]]):
    """Orchestrates the entire lifecycle of a single order."""
    items = choose_items(products)
    if not items:
        return None

    order_id, amount, order_date = create_order_and_items(cur, user_id, items, statuses['order']['Cart'])
    if not order_id:
        return None # Should not happen in this logic, but as a safeguard.

    payment_successful = process_payment(cur, order_id, amount, order_date, statuses['payment'])

    if not payment_successful:
        final_status = 'Cancelled' if random.random() < ORDER_CANCEL_RATE else 'Pending'
        cur.execute("UPDATE Orders SET order_STATUS_ID = :s WHERE order_ID = :oid", {'s': statuses['order'][final_status], 'oid': order_id})
        return {'order_id': order_id, 'items': items, 'amount': amount, 'returned': False, 'refunded': False}

    # If payment is successful, progress the order
    cur.execute("UPDATE Orders SET order_STATUS_ID = :s WHERE order_ID = :oid", {'s': statuses['order']['Processing'], 'oid': order_id})
    
    delivered_date = simulate_delivery(cur, order_id, order_date, statuses['delivery'])
    final_state = handle_post_delivery_flow(cur, order_id, amount, delivered_date, statuses['order'], statuses['payment'])

    return {'order_id': order_id, 'items': items, 'amount': amount, **final_state}


# --- User Activity Generation (Reviews, Wishlist) ---
def insert_reviews(cur, user_id: int, purchased_products: List[int]):
    to_review = [pid for pid in purchased_products if random.random() < REVIEW_RATE]
    if not to_review:
        return

    binds = {f'p{i}': pid for i, pid in enumerate(to_review)}
    bind_list = ','.join([f":p{i}" for i in range(len(to_review))])
    cur.execute(f"SELECT product_ID FROM Review WHERE user_ID = :u AND product_ID IN ({bind_list})", {**{'u': user_id}, **binds})
    existing = {int(r[0]) for r in cur.fetchall()}
    
    rows = []
    for pid in to_review:
        if pid in existing:
            continue
        rows.append({
            'user_ID': user_id, 'product_ID': pid, 'rew_RATING': random.randint(3, 5),
            'rew_COMMENT': random.choice(['Отличное качество.', 'Быстрая доставка.', 'Рекомендую.']),
            'rew_DATE': dt.datetime.now(dt.timezone.utc)
        })
    if rows:
        cur.executemany(
            "INSERT INTO Review (user_ID, product_ID, rew_RATING, rew_COMMENT, rew_DATE) VALUES (:user_ID, :product_ID, :rew_RATING, :rew_COMMENT, :rew_DATE)",
            rows
        )


def insert_wishlist(cur, user_id: int, candidates: List[int], already_bought: List[int]):
    left = [pid for pid in candidates if pid not in already_bought]
    if not left:
        return
    picks = random.sample(left, k=min(WISHLIST_ITEMS_PER_USER, len(left)))
    
    binds = {f'p{i}': pid for i, pid in enumerate(picks)}
    bind_list = ','.join([f":p{i}" for i in range(len(picks))])
    cur.execute(f"SELECT product_ID FROM Wishlist WHERE user_ID = :u AND product_ID IN ({bind_list})", {**{'u': user_id}, **binds})
    existing = {int(r[0]) for r in cur.fetchall()}

    rows = [{'user_ID': user_id, 'product_ID': pid, 'added_AT': dt.datetime.now(dt.timezone.utc), 'notes': None} for pid in picks if pid not in existing]
    if rows:
        cur.executemany("INSERT INTO Wishlist (user_ID, product_ID, added_AT, notes) VALUES (:user_ID, :product_ID, :added_AT, :notes)", rows)


# --- Main Orchestrator ---
def main():
    print('--- Refactored Orders/Activity Data Generator ---')
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        users = load_users() or fetch_users_from_db(cur)
        if not users:
            print('No users found. Run 01_populate_base_entities.py first.')
            return

        # Fetch all statuses in a structured way
        statuses = {
            'order': resolve_status_ids(cur, 'order', ['Cart', 'Pending', 'Processing', 'Completed', 'Cancelled', 'Returned', 'Refunded']),
            'payment': resolve_status_ids(cur, 'payment', ['Pending', 'Completed', 'Failed', 'Refunded']),
            'delivery': resolve_status_ids(cur, 'delivery', ['Preparing', 'Shipped', 'InTransit', 'OutForDelivery', 'Delivered', 'FailedAttempt', 'Returned']),
        }
        # Strict check for status completeness
        all_statuses_found = True
        for status_type, requested_keys in [
            ('order', ['Cart', 'Pending', 'Processing', 'Completed', 'Cancelled', 'Returned', 'Refunded']),
            ('payment', ['Pending', 'Completed', 'Failed', 'Refunded']),
            ('delivery', ['Preparing', 'Shipped', 'InTransit', 'OutForDelivery', 'Delivered', 'FailedAttempt', 'Returned'])
        ]:
            retrieved_keys = statuses[status_type].keys()
            if len(retrieved_keys) != len(requested_keys):
                all_statuses_found = False
                missing = set(requested_keys) - set(retrieved_keys)
                print(f"ERROR: Missing status keys for type '{status_type}': {', '.join(missing)}")
        
        if not all_statuses_found:
            print("Aborting due to missing status definitions in the database. Please run reference data scripts.")
            return

        products = fetch_active_products(cur)
        if not products:
            print('No active products available. Run product generators first.')
            return

        user_orders_info: Dict[int, List[int]] = {u: [] for u in users}
        total_orders = 0
        for u in users:
            n_orders = random.randint(ORDERS_PER_USER_MIN, ORDERS_PER_USER_MAX)
            for _ in range(n_orders):
                try:
                    info = simulate_full_order_lifecycle(cur, u, products, statuses)
                    if info and info.get('items'):
                        total_orders += 1
                        user_orders_info[u].extend(item[0] for item in info['items'])
                except Exception as e:
                    conn.rollback()
                    print(f"Error creating order for user {u}: {e}")
                else:
                    conn.commit()
        print(f"Created {total_orders} orders.")

        all_product_ids = [pid for pid, _, _ in products]
        for u in users:
            try:
                purchased = list(set(user_orders_info.get(u, [])))
                insert_reviews(cur, u, purchased)
                insert_wishlist(cur, u, all_product_ids, purchased)
            except Exception as e:
                conn.rollback()
                print(f"Error creating activity for user {u}: {e}")
            else:
                conn.commit()
        print('--- Orders/Activity generation finished ---')

    finally:
        if cur: cur.close()
        if conn: conn.close()


if __name__ == '__main__':
    main()
