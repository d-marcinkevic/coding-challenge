public class AssetManagementTaskBatch implements Database.Batchable<sObject>, Database.Stateful {

    public List<Id> orderIdList;
    public Integer recordsProcessed;
    public Integer recordsUpdated;
    
    public AssetManagementTaskBatch(List<Id> orderIdList) {
        this.orderIdList = orderIdList;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        recordsProcessed = 0;
        recordsUpdated = 0;
        
        return Database.getQueryLocator([SELECT Id, Item_Count__c, (SELECT Id, Provisioning_Date__c FROM OrderItems) FROM Order WHERE Id IN :orderIdList]);
    }
    
    public void execute(Database.BatchableContext bc, List<Order> records) {
        recordsProcessed += records.size();
        List<OrderItem> orderItemsToUpdate = new List<OrderItem>();
        try {
            for(Order order : records) {
                recordsProcessed += order.OrderItems.size();
                if(order.OrderItems.size() > 20) {
                    throw new OrchestrationUnrecoverableException('Order has more than 20 OrderItems');
                }
                order.Item_Count__c = order.OrderItems.size();
                for(OrderItem orderItem : order.OrderItems) {
                    orderItem.Provisioning_Date__c = Date.today();
                    orderItemsToUpdate.add(orderItem);
                }
            }
            
            Database.SaveResult[] saveResultOrderList = Database.update(records, false);
            for(Database.SaveResult saveResult : saveResultOrderList) {
                if (saveResult.isSuccess()) {
                    recordsUpdated += 1;
                }
            } 
            
            Database.SaveResult[] saveResultOrderItemList = Database.update(orderItemsToUpdate, false);
            for(Database.SaveResult saveResult : saveResultOrderItemList) {
                if (saveResult.isSuccess()) {
                    recordsUpdated += 1;
                }
            }
        } catch(OrchestrationRecoverableException e) {
            System.debug('Exception occurred: ' + e.getMessage());
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        System.debug('Records processed: ' + recordsProcessed);
        System.debug('Records updated: '+ recordsUpdated);
    }
    
}