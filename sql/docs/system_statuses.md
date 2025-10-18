# Система статусов в WinStore

## Общие принципы

В WinStore используется трехкомпонентная система статусов:
1. **OrderStatusTypes** - статусы заказа в целом
2. **PaymentStatusTypes** - статусы платежей
3. **DeliveryStatusTypes** - статусы доставки

Все таблицы статусов следуют единой структуре:
- Уникальный ID статуса
- Ключ статуса (строковый идентификатор)
- Локализованные названия и описания (RU, EN)
- Порядок отображения в интерфейсе

## Декларативное управление переходами статусов

Система использует таблицы *StatusTransitions для декларативного определения разрешенных переходов между статусами:

- **OrderStatusTransitions** - переходы статусов заказов
- **PaymentStatusTransitions** - переходы статусов платежей
- **DeliveryStatusTransitions** - переходы статусов доставки

Эти таблицы обеспечивают единый подход к валидации переходов статусов во всей системе:
1. **Документирование** бизнес-процессов непосредственно в структуре БД
2. **Валидация** допустимости перехода на уровне приложения
3. **Динамическое формирование UI** на основе доступных переходов
4. **Простое изменение** процессов без модификации кода

## Допустимые переходы статусов

### Заказы (Order)
1. Cart → Pending → Processing → Shipped → InTransit → Delivered → Completed
2. Альтернативные пути: Pending → Cancelled, Processing → Cancelled, Delivered → Returned → Refunded

### Платежи (Payment)
1. Pending → Processing → Completed
2. Альтернативные пути: Pending → Failed, Processing → Failed
3. Возвраты: Completed → Refunded, Completed → PartiallyRefunded, PartiallyRefunded → Refunded

### Доставка (Delivery)
1. Preparing → Shipped → InTransit → OutForDelivery → Delivered
2. Альтернативные пути: OutForDelivery → FailedAttempt → OutForDelivery, FailedAttempt → Returned, InTransit → Returned

## Диаграмма статусного автомата заказа

## Правила бизнес-логики

1. Заказ не может перейти в статус "Shipped", если его платеж не в статусе "Completed"
2. Заказ не может перейти в статус "Completed", пока его доставка не в статусе "Delivered"
3. Когда платеж переходит в "Refunded", заказ автоматически должен быть переведен в "Refunded"
4. Платеж не может перейти в статус "Refunded", если заказ не в статусе "Returned" или "Completed"
5. Статус доставки не может перейти в "Shipped", если заказ не в статусе "Processing" или выше

## Использование в приложении

### Универсальная валидация переходов статусов
Перед изменением любого статуса, приложение должно проверить допустимость перехода:
```python
def validate_status_transition(status_type, entity_id, current_status_id, new_status_id):
    """
    Проверяет допустимость перехода статуса.
    
    Args:
        status_type: Тип статуса ('Order', 'Payment', 'Delivery')
        entity_id: ID сущности (заказа, платежа)
        current_status_id: Текущий ID статуса
        new_status_id: Новый ID статуса
        
    Returns:
        Tuple[bool, str]: (допустимость перехода, название перехода)
    """
    with connection.cursor() as cursor:
        cursor.execute("""
            DECLARE @IsValid BIT, @TransitionName NVARCHAR(100)
            EXEC dbo.sp_ValidateStatusTransition
                @StatusType = %s,
                @FromStatusID = %s, 
                @ToStatusID = %s, 
                @IsValid = @IsValid OUTPUT, 
                @TransitionName = @TransitionName OUTPUT
            SELECT @IsValid AS is_valid, @TransitionName AS transition_name
        """, [status_type, current_status_id, new_status_id])
        result = cursor.fetchone()
        return result[0], result[1]  # is_valid, transition_name
```

### Отображение доступных действий для разных типов статусов
```python
def get_available_status_transitions(status_type, current_status_id):
    """
    Получает список доступных переходов статуса для формирования UI.
    
    Args:
        status_type: Тип статуса ('Order', 'Payment', 'Delivery')
        current_status_id: Текущий ID статуса
        
    Returns:
        List[Dict]: Список доступных переходов
    """
    stored_procedure = {
        'Order': 'dbo.sp_GetAvailableOrderStatusTransitions',
        'Payment': 'dbo.sp_GetAvailablePaymentStatusTransitions',
        'Delivery': 'dbo.sp_GetAvailableDeliveryStatusTransitions'
    }.get(status_type)
    
    if not stored_procedure:
        return []
        
    with connection.cursor() as cursor:
        cursor.execute(f"EXEC {stored_procedure} @CurrentStatusID = %s", [current_status_id])
        return dictfetchall(cursor)
```

### Пример интеграции с Django ORM

```python
# models.py
class Order(models.Model):
    # ... другие поля
    order_status = models.ForeignKey('OrderStatusType', on_delete=models.PROTECT)
    
    def set_status(self, new_status_id):
        """
        Изменяет статус заказа с проверкой допустимости перехода.
        
        Args:
            new_status_id: ID нового статуса
            
        Returns:
            bool: Успешность изменения статуса
        """
        is_valid, transition_name = validate_status_transition(
            'Order', self.id, self.order_status_id, new_status_id)
        
        if not is_valid:
            logger.error(f"Invalid status transition for Order#{self.id}: "
                         f"{self.order_status_id} -> {new_status_id}")
            return False
        
        # Обновляем статус и логируем
        self.order_status_id = new_status_id
        self.save(update_fields=['order_status'])
        
        # Логируем изменение статуса
        StatusTransitionLog.objects.create(
            entity_type='Order',
            entity_id=self.id,
            from_status_id=self.order_status_id,
            to_status_id=new_status_id,
            transition_name=transition_name,
            created_by=get_current_user_id()
        )
        
        return True

# Пример использования в сервисном слое
def process_order(order_id):
    order = Order.objects.get(id=order_id)
    payment = Payment.objects.filter(order_id=order_id).first()
    
    # Проверяем условия для перехода к обработке
    if payment and payment.payment_status_id == PAYMENT_STATUS_COMPLETED:
        # Доступные переходы для текущего статуса
        available_transitions = get_available_status_transitions('Order', order.order_status_id)
        
        # Находим ID статуса "Processing"
        processing_status = next(
            (t for t in available_transitions if t['status_key'] == 'Processing'), 
            None
        )
        
        if processing_status:
            # Изменяем статус с валидацией
            return order.set_status(processing_status['to_status_id'])
    
    return False
```

*Примечание: Все таблицы переходов статусов служат как единая точка истины для правил переходов, что обеспечивает согласованность и надежность бизнес-процессов.*
