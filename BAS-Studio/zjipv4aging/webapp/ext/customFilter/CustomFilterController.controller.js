sap.ui.define([
    "sap/ui/model/Filter",
    "sap/ui/model/FilterOperator"
], function (Filter, FilterOperator) {
    "use strict";

    return {

        /**
         * OVP extension hook: returns custom filter object to merge with SmartFilterBar filters.
         * Follows Custom-Filters-OVP.md official documentation pattern.
         */
        getCustomFilters: function () {
            var aFilters = [];
            var oView = this.oView;
            if (!oView) {
                return undefined;
            }

            // --- 1. Plant (MultiComboBox — dynamic) ---
            var oPlantCombo = oView.byId("customPlantFilter");
            if (oPlantCombo) {
                var aPlants = oPlantCombo.getSelectedKeys();
                if (aPlants.length > 0) {
                    aPlants.forEach(function (sKey) {
                        aFilters.push(new Filter("Plant", FilterOperator.EQ, sKey));
                    });
                }
            }

            // --- 2. Activity Type (MultiComboBox — static) ---
            var oActivityCombo = oView.byId("customActivityTypeFilter");
            if (oActivityCombo) {
                var aActivities = oActivityCombo.getSelectedKeys();
                if (aActivities.length > 0) {
                    aActivities.forEach(function (sKey) {
                        aFilters.push(new Filter("ActivityType", FilterOperator.EQ, sKey));
                    });
                }
            }

            // --- 3. Aging Bucket (MultiComboBox — static) ---
            var oAgingBucketCombo = oView.byId("customAgingBucketFilter");
            if (oAgingBucketCombo) {
                var aBuckets = oAgingBucketCombo.getSelectedKeys();
                if (aBuckets.length > 0) {
                    aBuckets.forEach(function (sKey) {
                        aFilters.push(new Filter("AgingBucket", FilterOperator.EQ, sKey));
                    });
                }
            }

            // --- 4. WM/EWM Type (Switch) ---
            var oWmEwmSwitch = oView.byId("customWmEwmSwitch");
            if (oWmEwmSwitch) {
                var bEwm = oWmEwmSwitch.getState();
                aFilters.push(new Filter("WmEwmType", FilterOperator.EQ, bEwm ? "EWM" : "WM"));
            }

            // --- 5. Current Milestone (MultiComboBox — static) ---
            var oMilestoneCombo = oView.byId("customMilestoneFilter");
            if (oMilestoneCombo) {
                var aMilestones = oMilestoneCombo.getSelectedKeys();
                if (aMilestones.length > 0) {
                    aMilestones.forEach(function (sKey) {
                        aFilters.push(new Filter("CurrentMilestone", FilterOperator.EQ, sKey));
                    });
                }
            }

            // --- 6. PeriodMonth (MultiComboBox — static) ---
            var oPeriodMonthCombo = oView.byId("customPeriodMonthFilter");
            if (oPeriodMonthCombo) {
                var aMonths = oPeriodMonthCombo.getSelectedKeys();
                if (aMonths.length > 0) {
                    aMonths.forEach(function (sKey) {
                        aFilters.push(new Filter("PeriodMonth", FilterOperator.EQ, sKey));
                    });
                }
            }

            if (aFilters.length > 0) {
                return new Filter(aFilters, true);
            }
        },

        /**
         * OVP extension hook: saves custom filter state for variant / bookmark.
         */
        getCustomAppStateDataExtension: function (oCustomData) {
            if (!oCustomData) { return; }
            var oView = this.oView;
            if (!oView) { return; }

            var oPlant = oView.byId("customPlantFilter");
            var oActivity = oView.byId("customActivityTypeFilter");
            var oAging = oView.byId("customAgingBucketFilter");
            var oSwitch = oView.byId("customWmEwmSwitch");
            var oMilestone = oView.byId("customMilestoneFilter");
            var oPeriod = oView.byId("customPeriodMonthFilter");

            if (oPlant) { oCustomData.plant = oPlant.getSelectedKeys(); }
            if (oActivity) { oCustomData.activityType = oActivity.getSelectedKeys(); }
            if (oAging) { oCustomData.agingBucket = oAging.getSelectedKeys(); }
            if (oSwitch) { oCustomData.wmEwmType = oSwitch.getState() ? "EWM" : "WM"; }
            if (oMilestone) { oCustomData.milestone = oMilestone.getSelectedKeys(); }
            if (oPeriod) { oCustomData.periodMonth = oPeriod.getSelectedKeys(); }
        },

        /**
         * OVP extension hook: restores custom filter state from variant / bookmark.
         */
        restoreCustomAppStateDataExtension: function (oCustomData) {
            if (!oCustomData) { return; }
            var oView = this.oView;
            if (!oView) { return; }

            var oPlant = oView.byId("customPlantFilter");
            var oActivity = oView.byId("customActivityTypeFilter");
            var oAging = oView.byId("customAgingBucketFilter");
            var oSwitch = oView.byId("customWmEwmSwitch");
            var oMilestone = oView.byId("customMilestoneFilter");
            var oPeriod = oView.byId("customPeriodMonthFilter");

            if (oPlant && oCustomData.plant) { oPlant.setSelectedKeys(oCustomData.plant); }
            if (oActivity && oCustomData.activityType) { oActivity.setSelectedKeys(oCustomData.activityType); }
            if (oAging && oCustomData.agingBucket) { oAging.setSelectedKeys(oCustomData.agingBucket); }
            if (oSwitch && oCustomData.wmEwmType !== undefined) { oSwitch.setState(oCustomData.wmEwmType === "EWM"); }
            if (oMilestone && oCustomData.milestone) { oMilestone.setSelectedKeys(oCustomData.milestone); }
            if (oPeriod && oCustomData.periodMonth) { oPeriod.setSelectedKeys(oCustomData.periodMonth); }
        }
    };
});
