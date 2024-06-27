import { LightningElement, api, track } from 'lwc';
import { getLocations } from 'c/apexUtils'
import {
    toastEvents,modalEvents
} from 'c/utils';

export default class UserLocation extends LightningElement {
    @api contactId;
    @api userTriplogId;
    @api accountId;
    myLocation = false;
    addLocation = true;
    manualMileageList;
    @track locationsList;
        /* Stores File Name */
    fileName;

    /* Stores file size */
    fSize;

    /* flag for error */ 
    errorUploading;

    /* Flag for result */
    fileResult;

    /* other fields */
    choosefile;
    fileList = {};
    chooseFileName = '';
    chunkSize = 950000; //Maximum Javascript Remoting message size is 1,000,000 
    attachment;
    attachmentName;
    fileSize;
    positionIndex;
    doneUploading;
    driverObject;
    isError = false;
    isVisible = false;
    
    /* Hide / Show Spinner */
    isSpinner = false;

    /* checks if file is uploaded successfully */
    isUploaded = false;

    @api 
    async generateView(){
        let btnItem = this.template.querySelectorAll(".btn-toggle");
        btnItem.forEach((el) => {
         el.classList.remove("is-active");
        });
        this.template.querySelector('.my-trip').classList.add("is-active");
        this.locationsList = await getLocations(this.contactId);
        this.addLocation = false;
        this.myLocation = true;
    }

    renderedCallback() {
        const buttonItem = this.template.querySelectorAll(".btn-toggle");
    
        buttonItem.forEach((el) =>
          el.addEventListener("click", () => {
            buttonItem.forEach((el2) => el2.classList.remove("is-active"));
            el.classList.add("is-active");
          })
        );
    }

    handleAddLocation() {
        this.myLocation = false;
        this.addLocation = true;
    }

    handleMyLocation(){
        this.myLocation = true;
        this.addLocation = false;
        //this.locationsList = await getLocations(this.contactId);
    }

    showSpinner(event){
        toastEvents(this, event.detail);
    }

    showModal(event){
        modalEvents(this, event.detail);
    }

    showListModal(event){
        this.dispatchEvent(
            new CustomEvent("listmodal", {
              detail: event.detail
            })
          );
    }

    showErrorToast(event){
        this.dispatchEvent(
            new CustomEvent("error", {
                detail: event.detail
            })
        );
    }
    async connectedCallback(){
        this.locationsList = await getLocations(this.contactId);
        console.log('location list', this.locationsList);
    }
}