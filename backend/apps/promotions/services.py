from decimal import Decimal
from datetime import datetime
from typing import Optional, List, Dict, Any, Tuple, Union
from django.db import transaction
from django.core.exceptions import ValidationError

from .models import Promotion, PromotionApplication
from apps.orders.models import Order, OrderItem
from apps.products.models import Product, Category


class PromotionService:
    """
    Service for handling all promotion-related business logic.
    This keeps complex logic in the application layer for better testability and maintenance.
    """
    
    @classmethod
    def validate_and_apply_promotion(cls, order_id: int, promo_code: str) -> Dict[str, Any]:
        """
        Validates a promotion code and applies it to an order if valid.
        
        Args:
            order_id: The ID of the order to apply the promotion to
            promo_code: The promotion code to validate and apply
            
        Returns:
            Dict containing result status and savings amount
            
        Raises:
            ValidationError: If the promotion code is invalid or cannot be applied
        """
        # Step 1: Get the promotion by code
        try:
            promotion = Promotion.objects.get(promo_code=promo_code, is_active=True)
        except Promotion.DoesNotExist:
            raise ValidationError("Invalid promotion code")
        
        # Step 2: Validate promotion is within valid date range
        now = datetime.now()
        if not (promotion.valid_from <= now <= promotion.valid_to):
            raise ValidationError("Promotion code has expired or is not yet active")
        
        # Step 3: Check usage limits
        if promotion.max_uses is not None and promotion.current_uses >= promotion.max_uses:
            raise ValidationError("This promotion code has reached its usage limit")
        
        # Step 4: Get the order
        try:
            order = Order.objects.get(id=order_id)
        except Order.DoesNotExist:
            raise ValidationError("Order not found")
            
        # Step 5: Check minimum purchase requirement
        if order.order_amount < promotion.min_purchase:
            raise ValidationError(
                f"Order total must be at least {promotion.min_purchase} to use this promotion"
            )
        
        # Step 6: Check if promotion applies to items in the order
        if not cls._is_promotion_applicable(promotion, order):
            raise ValidationError("This promotion cannot be applied to the items in your order")
            
        # Step 7: Calculate discount amount based on promotion type
        savings = cls._calculate_discount(promotion, order)
        
        # Step 8: Apply promotion to order via database
        with transaction.atomic():
            # Use the simplified stored procedure to update the database
            from django.db import connection
            with connection.cursor() as cursor:
                cursor.execute(
                    "EXEC dbo.sp_AssociatePromoWithOrder @OrderID=%s, @PromoID=%s, @PromoSavings=%s",
                    [order_id, promotion.id, savings]
                )
                
        return {
            "result": "Promotion applied successfully",
            "savings": savings,
            "order_id": order_id,
            "promotion_id": promotion.id
        }
    
    @staticmethod
    def _calculate_discount(promotion: Promotion, order: Order) -> Decimal:
        """Calculate discount amount based on promotion type and order details"""
        if promotion.discount_type == 'percentage':
            return order.order_amount * (promotion.discount_value / 100)
        elif promotion.discount_type == 'fixed':
            return min(promotion.discount_value, order.order_amount)  # Don't exceed order total
        elif promotion.discount_type == 'shipping':
            # This would integrate with your shipping calculation logic
            return promotion.discount_value
        return Decimal('0.00')
    
    @staticmethod
    def _is_promotion_applicable(promotion: Promotion, order: Order) -> bool:
        """
        Check if the promotion applies to the items in the order based on 
        the promotion's application rules.
        """
        # First, get all application rules for this promotion
        applications = PromotionApplication.objects.filter(promo_id=promotion.id)
        
        # If no specific applications, promotion applies to all
        if not applications.exists():
            return True
            
        # Check if there's an 'all' type application
        if applications.filter(target_type='all').exists():
            return True
            
        # Get order items and their product IDs
        order_items = OrderItem.objects.filter(order_id=order.id)
        product_ids = [item.product_id for item in order_items]
        products = Product.objects.filter(id__in=product_ids)
        
        # Check product-specific applications
        product_applications = applications.filter(
            target_type='product', 
            target_id__in=product_ids
        )
        if product_applications.exists():
            return True
            
        # Check category-specific applications
        category_ids = [product.category_id for product in products]
        category_applications = applications.filter(
            target_type='category', 
            target_id__in=category_ids
        )
        if category_applications.exists():
            return True
            
        return False


class WishlistService:
    """
    Service for handling wishlist-related business logic.
    """
    # Implementation for wishlist management...
