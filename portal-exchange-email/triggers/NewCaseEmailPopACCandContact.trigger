trigger NewCaseEmailPopACCandContact on Case (before update) {
    NewCaseEmailPopACCandContactHandler.handleCaseUpdates(Trigger.new, Trigger.oldMap);
}