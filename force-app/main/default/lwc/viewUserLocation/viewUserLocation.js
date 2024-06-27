import { LightningElement, api, track } from 'lwc';
import resourceImage from '@salesforce/resourceUrl/mBurseCss';
import { toLocation, getLocations } from "c/apexUtils";
import {
    toastEvents, modalEvents
} from 'c/utils';
export default class ViewUserLocation extends LightningElement {
    @api contactId;
    @api location;
    @track locationModelList;
    @track updateList;
    classToTable = 'fixed-container';
    column;
    noMessage = 'There is no location data available'
    refreshList;
    resultUpdateLocation;
    isEditMode;
    keyFields;
    locationKeyFields = ["name", "address", "range"]
    locationColumn = [{
            id: 1,
            name: "Location Name",
            colName: "name",
            colType: "String",
            arrUp: true,
            arrDown: false
        },
        {
            id: 2,
            name: "Location Address",
            colName: "address",
            colType: "String",
            arrUp: false,
            arrDown: false,
        },
        {
            id: 3,
            name: "Range (ft)",
            colName: "range",
            colType: "Integer",
            arrUp: false,
            arrDown: false
        }
    ];
    isSortable = false;
    _value = "";
    isScrollable = false;
    isSearchEnable = true;
    paginatedModal = false;
    editableView = false;
    searchIcon = resourceImage + '/mburse/assets/mBurse-Icons/Vector.png';
    proxyToObject(e) {
        return JSON.parse(e)
    }

    mapOrder(array, order, key) {
        array.sort(function (a, b) {
            var A = a[key],
                B = b[key];
            if (order.indexOf(A) > order.indexOf(B)) {
                return 1;
            }
            return -1;
        });

        return array;
    }

    handleClearInput(){
        this._value = "";
        this.isSearchEnable = this._value === "" ? true : false;
        this.template
        .querySelector("c-user-preview-table")
        .searchByKey(this._value);
    }

    dynamicBinding(data, keyFields) {
        data.forEach(element => {
            let model = [];
            for (const key in element) {
                if (Object.prototype.hasOwnProperty.call(element, key)) {
                    let singleValue = {}
                    if (keyFields.includes(key) !== false) {
                        singleValue.key = key;
                        singleValue.value = (element[key] === "null" || element[key] === null) ? "" : element[key];
                        singleValue.truncate = (key === 'name' || key === 'address') ? true : false;
                        singleValue.tooltip = (key === 'name' || key === 'address') ? true : false;
                        singleValue.tooltipText =  (key === 'name' || key === 'address') ? (element[key] != null) ? element[key] : 'This trip was manually entered without an address.' : "";
                        // singleValue.isCurrency = (key === 'variableamount' || key === 'VariableRate' || key === 'variableRate'  || key === 'varibleAmount' || key === 'fixed1' || key === 'fixed2' || key === 'fixed3' || key === 'totalFixedAmount') ? true : false;
                        model.push(singleValue);
                    }
                }
            }
            element.isEdited = false;
            element.keyFields = this.mapOrder(model, keyFields, 'key');
        });
    }

    handleChange(event) {
		this._value = event.target.value;
        this.isSearchEnable = this._value === "" ? true : false;
        this.template.querySelector('c-user-preview-table').searchByKey(this._value, this.locationModelList)
	}

    editMode(){
        this.isEditMode = true;
    }

    handleUpdateList(event){
        //this.locationModelList = [];
        this.updateList = this.proxyToObject(event.detail);
        console.log("this.update", this.updateList)
    }

    async updateLocations(){
        toastEvents(this, 'Please wait while your locations being updated.');
        let array = this.updateList;
        // eslint-disable-next-line no-unused-vars
        const newLocationArr = array.map(({keyFields,isEdited, ...rest}) => { // Removes certain keys from objects of array "keyFields, isEdited"
            return rest;
        });

       const newMlogArr = array.map((ele) => {
            const o = {...ele}; // does not mutuate original array by using spread operator as it creates copy
            o["range (ft)"] = o.range;
            delete o.keyFields;
            delete o.isEdited;
            delete o.range;
            return o;
        });
     
        this.resultUpdateLocation = await toLocation(JSON.stringify(newLocationArr), this.contactId, JSON.stringify(newMlogArr));
        if(this.resultUpdateLocation === 'Success'){
            toastEvents(this, 'Hide');
            modalEvents(this, 'Your location has been updated');
            this.isEditMode = false;
            if(this.template.querySelector('.filter-input')){
                this.template.querySelector('.filter-input').value = "";
            }
            this.refreshList = await getLocations(this.contactId);
            this.locationModelList =  this.proxyToObject(this.refreshList);
            this.dynamicBinding(this.locationModelList, this.keyFields);
            this.template.querySelector('c-user-preview-table').refreshTable(this.locationModelList);
        }else{
            toastEvents(this, 'Hide');
            this.dispatchEvent(
                new CustomEvent("error", {
                    detail: 'Unable to update your locations. Please try again'
                })
            );
        }
    }

    cancelEditMode(){
        this.isEditMode = false;
        if(this.template.querySelector('.filter-input')){
            this.template.querySelector('.filter-input').value = "";
        }
        this.template.querySelector('c-user-preview-table').refreshTable(this.locationModelList);
    }

    connectedCallback(){
        console.log("this.location", this.location)
        if (this.location) {
            this.locationModelList = this.proxyToObject(this.location);
            this.column = this.locationColumn;
            this.keyFields = this.locationKeyFields;
            this.isSortable = true;
            this.editableView = true;
            if (this.locationModelList !== undefined) {
                this.classToTable = this.locationModelList.length > 6 ? 'fixed-container' : 'fixed-container overflow-none';
                this.isScrollable = this.locationModelList.length > 6 ? true : false;
                this.paginatedModal = true;
                this.dynamicBinding(this.locationModelList, this.keyFields);
            }

          
        }
    }
}