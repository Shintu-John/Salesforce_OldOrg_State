import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getAvailableSites from '@salesforce/apex/Utility_Community.getAvailableSites';
import getJobs from '@salesforce/apex/Utility_Community.getDepotInformations';


export default class DepotViewCommunity extends LightningElement {
    
    jobs = [];
    tableData = [];

    @track error;
    @track selectedSite;
    @track sortedBy = 'collectionDate';      // To hold the field name that is currently sorted by
    @track sortedDirection = 'desc';  // To hold the sort direction
    @track isLoading = true;

    @wire(getAvailableSites)
    wiredSites({ error, data }) {
        if (data) {
            this.siteOptions = data.map(site => ({
                label: `${site.Name} (${site.Postalcode__c})`,
                value: site.Id
            }));
            console.log('data :: ', data);
        } else if (error) {
            this.error = error;
            console.error(error);
        }
        this.isLoading = false;
    }

    @track siteOptions = [];
    selectedSiteIds = [];
    onSiteSelectionChangeHandler(event) {
        this.selectedSiteIds = [...event.detail.selectedOptionValues];
    }
    
    handleSearchJobs() {
        if (!(this.selectAll || this.selectedSiteIds.length > 0)) {
            this.showToast('', 'Please select a Site.', 'Warning');
            return;
        }
        
        this.fetchJobs();
    }
    
    fetchJobs() {
        this.jobs = [];
        this.isLoading = true;
        getJobs({
            siteIds: this.selectedSiteIds
        })
            .then(result => {
                this.jobs = result;
                console.log('jobs :: ', this.jobs);
            })
            .catch(error => {
                this.error = error;
                console.log('error :: ', this.error);
            }).finally(() => {
                this.applySorting();
                this.isLoading = false;
            });
    }
    
    handleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.sortedBy = sortedBy;
        this.sortedDirection = sortDirection;
        this.applySorting();
    }

    applySorting() {
        let sortedBy = this.sortedBy;
        let sortDirection = this.sortedDirection;
        
        const cloneData = [...this.jobs];

        // Sort the data array
        cloneData.sort((a, b) => {
            let valueA = a[sortedBy] ? a[sortedBy] : '';
            let valueB = b[sortedBy] ? b[sortedBy] : '';

            // Compare the two values based on the field type
            return sortDirection === 'asc'
                ? (valueA > valueB) - (valueA < valueB)
                : (valueB > valueA) - (valueB < valueA);
        });

        // Update the data and sorted state
        this.jobs = cloneData;
        this.groupData();
    } 
    
   groupData() {
    const result = this.jobs.reduce((acc, item) => {
        const { supplierName, depotDispose, wasteType, ewcCode, deliveryDate, licenseNumber, licenseExpiry } = item;

        // Convert deliveryDate to a Date object (handle null values by setting to null)
        const deliveryDateObj = deliveryDate ? new Date(deliveryDate) : null;

        // Check if supplierName exists in the result
        if (!acc[supplierName]) {
            acc[supplierName] = { supplierName, link : '/' + item.supplierId, depots: {}, rowspan: 0, firstService: null, lastService: null, licenseNumber, licenseExpiry };
        }

        // Check if depotDispose exists under supplierName
        if (!acc[supplierName].depots[depotDispose]) {
            acc[supplierName].depots[depotDispose] = { depotDispose, link : '/' + item.depotDisposeId, wasteTypes: {}, rowspan: 0, firstService: null, lastService: null };
        }

        // Check if wasteType exists under depotDispose
        if (!acc[supplierName].depots[depotDispose].wasteTypes[wasteType]) {
            acc[supplierName].depots[depotDispose].wasteTypes[wasteType] = { wasteType, ewcCodes: {}, rowspan: 0, firstService: null, lastService: null };
        }
        let newEwcCode = false;
        // Check if ewcCode exists under wasteType
        if (!acc[supplierName].depots[depotDispose].wasteTypes[wasteType].ewcCodes[ewcCode]) {
            newEwcCode = true;
            acc[supplierName].depots[depotDispose].wasteTypes[wasteType].ewcCodes[ewcCode] = {
                ewcCode, jobs: [], rowspan: 0, firstService: null, lastService: null 
            };
        }

        acc[supplierName].depots[depotDispose].wasteTypes[wasteType].ewcCodes[ewcCode].jobs.push(item);
        
        // Update firstService and lastService for the ewcCode level
        const ewcCodeGroup = acc[supplierName].depots[depotDispose].wasteTypes[wasteType].ewcCodes[ewcCode];
        if (deliveryDateObj) {
            ewcCodeGroup.firstService = ewcCodeGroup.firstService
                ? new Date(Math.min(ewcCodeGroup.firstService, deliveryDateObj))
                : deliveryDateObj;
            ewcCodeGroup.lastService = ewcCodeGroup.lastService
                ? new Date(Math.max(ewcCodeGroup.lastService, deliveryDateObj))
                : deliveryDateObj;
        } 
        
        if(newEwcCode){
            const wasteTypeGroup = acc[supplierName].depots[depotDispose].wasteTypes[wasteType];
            const depotGroup = acc[supplierName].depots[depotDispose];
            const supplierGroup = acc[supplierName];
            
            ewcCodeGroup.rowspan++;
            wasteTypeGroup.rowspan++;
            depotGroup.rowspan++;
            supplierGroup.rowspan++;
        }
        
        return acc;
    }, {});

    // Convert the result to a format suitable for rendering
    this.tableData = Object.values(result).map(supplierData => {
        supplierData.depots = Object.values(supplierData.depots).map(depotData => {
            depotData.wasteTypes = Object.values(depotData.wasteTypes).map(wasteTypeData => {
                wasteTypeData.ewcCodes = Object.values(wasteTypeData.ewcCodes);
                return wasteTypeData;
            });
            return depotData;
        });
        return supplierData;
    });

    console.log('tableData', this.tableData);
}


    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }

}