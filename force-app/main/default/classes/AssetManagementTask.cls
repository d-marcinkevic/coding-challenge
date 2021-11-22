public class AssetManagementTask implements OrchestrationTask {

    public void executeBatch(List<Id> orderIdList) {
        Database.executeBatch(new AssetManagementTaskBatch(orderIdList), 200);
    }
}