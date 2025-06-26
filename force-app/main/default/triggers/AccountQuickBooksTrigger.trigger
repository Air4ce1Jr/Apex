trigger AccountQuickBooksTrigger on Account (after insert, after update) {
    if (Trigger.isAfter && !QuickBooksTriggerUtil.skipAsync) {
        QuickBooksSyncJob job = new QuickBooksSyncJob('Account', new List<Id>(Trigger.newMap.keySet()));
        if (System.Test.isRunningTest() && QuickBooksTriggerUtil.runInline) {
            job.execute(null);
        } else {
            System.enqueueJob(job);
        }
    }
}
