trigger AccountQuickBooksTrigger on Account (after insert, after update) {
    if (Trigger.isAfter && !QuickBooksTriggerUtil.skipAsync && !QuickBooksSyncJob.skipAsync && !Test.isRunningTest()) {
        System.enqueueJob(new QuickBooksSyncJob('Account', new List<Id>(Trigger.newMap.keySet())));
    }
}
