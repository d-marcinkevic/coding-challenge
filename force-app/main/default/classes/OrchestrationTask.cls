public interface OrchestrationTask {
	void executeBatch(List<Id> orderIdList);
}