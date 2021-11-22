@isTest
public class AssetManagementTaskTest {

    @TestSetup
    static void createTestData() {
        
        List<Order> orders = new List<Order>();
        List<OrderItem> orderItems = new List<OrderItem>();
        
        Product2 product = new Product2(Name = 'Test Product');
        insert product;
        
        // PricebookEntry with standard Pricebook
        insert new PricebookEntry(Pricebook2id = Test.getStandardPricebookId(), Product2Id = product.id, Unitprice = 1.0, IsActive = true);

        Pricebook2 pricebook = new Pricebook2(Name = 'Test Pricebook');
		insert pricebook;
        
        // PricebookEntry with custom Pricebook
        PricebookEntry pricebookEntry = new PricebookEntry(Pricebook2id = pricebook.id, Product2id = product.id, Unitprice=1.0, IsActive=true);
		insert pricebookEntry;
        
        Account account = new Account(Name = 'Test Account');
        insert account;
        
        Contract contract = new Contract(Status = 'Draft', 
                                         AccountId = account.Id, 
                                         StartDate = Date.today(), 
                                         ContractTerm = 2);
        insert contract;
        
        // Orders creation
        for(Integer i = 0; i < 200; i++) {
            Order order = new Order(AccountId = account.Id, 
                                    ContractId = contract.Id, 
                                    Status = 'Draft', 
                                    Pricebook2Id = pricebook.Id,
                                    EffectiveDate = Date.today());
            orders.add(order);
        }
        insert orders;
        
        // Order products creation
        for(Order order : orders) {
            for(Integer i = 0; i < 20; i++) {
                OrderItem orderItem = new OrderItem(OrderId = order.Id, 
                                                    Quantity = 1, 
                                                    UnitPrice = 1.0,
                                                    Product2Id = product.Id, 
                                                    PricebookEntryId = pricebookEntry.Id);
                orderItems.add(orderItem);
            }
        }
        insert orderItems;
    }
    
    @isTest
    static void executeBatchTest_Valid() {
		List<Order> orders = [SELECT Id, Item_Count__c, (SELECT Id, Provisioning_Date__c FROM OrderItems) FROM Order];
        List<Id> orderIds = new List<Id>();
        for(Order order : orders) {
            orderIds.add(order.Id);
        }
        
        System.assertEquals(null, orders[0].Item_Count__c);
        System.assertEquals(null, orders[0].OrderItems[0].Provisioning_Date__c);
        
        Test.startTest();
        OrchestrationTask orchestrationTask = new AssetManagementTask();
        orchestrationTask.executeBatch(orderIds);
        Test.stopTest();
        
        List<Order> updatedOrders = [SELECT Id, Item_Count__c, (SELECT Id, Provisioning_Date__c FROM OrderItems) FROM Order];
        System.assertNotEquals(null, updatedOrders[0].Item_Count__c);
        System.assertNotEquals(null, updatedOrders[0].OrderItems[0].Provisioning_Date__c);
    }
    
    @isTest
    static void executeBatchTest_TooManyOrderItems_Invalid() {
        List<Order> orders = [SELECT Id, Item_Count__c, (SELECT Id, Provisioning_Date__c FROM OrderItems) FROM Order];
        List<Id> orderIds = new List<Id>();
        for(Order order : orders) {
            orderIds.add(order.Id);
        }
        Product2 product = [SELECT Id FROM Product2 WHERE Name = 'Test Product'];
        Pricebook2 pricebook = [SELECT Id FROM Pricebook2 WHERE Name = 'Test Pricebook'];
        PricebookEntry pricebookEntry = [SELECT Id FROM PricebookEntry WHERE Pricebook2id = :pricebook.Id AND Product2id = :product.Id];
        OrderItem orderItem = new OrderItem(OrderId = orders[100].Id, 
                                            Quantity = 1, 
                                            UnitPrice = 1.0,
                                            Product2Id = product.Id, 
                                            PricebookEntryId = pricebookEntry.Id);
        insert orderItem;
        
        Test.startTest();
        try {
            OrchestrationTask orchestrationTask = new AssetManagementTask();
        	orchestrationTask.executeBatch(orderIds);
        } catch(OrchestrationUnrecoverableException e) {
            System.assertEquals('Order has more than 20 OrderItems', e.getMessage());
        }
        Test.stopTest();
    }
}