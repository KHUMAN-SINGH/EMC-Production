/* eslint-disable vars-on-top */
import { LightningElement, api } from 'lwc';
import emcCss from '@salesforce/resourceUrl/EmcCSS';
import sheetWorkbook from '@salesforce/resourceUrl/xlsx';
import workbook from '@salesforce/resourceUrl/EMC_Header_Scripts';
import { loadScript } from "lightning/platformResourceLoader";
import {
    toastEvents, modalEvents
} from 'c/utils';
import { uploadLocations } from "c/apexUtils";
export default class LocationUpload extends LightningElement {
    @api userTriplogId;
    @api accountId;
    @api contactId;
    resultLocation;
    contentMessage = '';
    nameOfLocationFile = 'sample_location_import';
    headers = {
        "Name (optional)": "Name (optional)",
        "Address": "Address",
        "Range(in feet put 300 if you are not sure)":  "Range(in feet put 300 if you are not sure)"
    }
    locationTemplate = [{
        "Name (optional)": "The White House",
        "Address": "1600 Pennsylvania Ave NW, Washington, DC 20500",
        "Range(in feet put 300 if you are not sure)": 300
    }
    ]
    location = emcCss + '/emc-design/assets/images/Icons/PNG/Green/Locations.png';
    /* Stores File Name */
    fileName;

    /* Stores file size */
    fSize;

    /* flag for error */
    errorUploading;
    
    /*flag for rendered callback*/
    renderInitialized = false;

    /* Flag for result */
    fileResult;

    /* other fields */
    choosefile;
    fileList = {};
    chooseFileName = '';
    chunkSize = 950000; //Maximum Javascript Remoting message size is 1,000,000 
    attachment;
    attachmentName;
    attachmentLocation;
    mLogLocation;
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
    renderedCallback() {
        if (this.renderInitialized) {
            return;
        }
        this.renderInitialized = true;
        Promise.all([
            loadScript(this, sheetWorkbook),
            loadScript(this, workbook + "/EMC_Header_Scripts/js/jszip.js"),
            loadScript(this, workbook + "/EMC_Header_Scripts/js/FileSaver.min.js")
        ])
        .then(() => {
            console.log("success");
        })
        .catch(error => {
            console.log("failure", error);
        });
        if (this.template.querySelector('form') != null) {
            this.template.querySelector('form').addEventListener(
                'submit',
                this._handler = (event) => this.handleFormSubmit(event)
            );
        }
    }

    /* Styling for error messages */
    toggleBoxError() {
        this.isError = true;
        this.isVisible = false;
        this.template.querySelector('.box').classList.add('has-advanced-upload-error');
        this.template.querySelector('.box').classList.remove('has-advanced-upload');
        this.template.querySelector('.file-message').classList.add('pd-10');
        this.template.querySelector('.file-message').classList.remove('pd-3');
    }

    /* Styling for default file upload UI */
    toggleBox() {
        this.isError = false;
        this.isVisible = true;
        this.template.querySelector('.box').classList.remove('has-advanced-upload-error');
        this.template.querySelector('.box').classList.add('has-advanced-upload');
        this.template.querySelector('.file-message').classList.remove('pd-10');
        this.template.querySelector('.file-message').classList.add('pd-3');
    }

    /* Function to read the file */
    fileReader(baseTarget) {
        var fileSize, choosenfileType = '',
            photofile, reader, fileExt, i = 0,
            exactSize, fIndex, subString;
        this.choosefile = baseTarget;
        if (this.choosefile) {
            console.log(this.choosefile.files)
            fileSize = this.choosefile.files[0].size;
            photofile = baseTarget.files[0];
            choosenfileType = photofile.type;
            this.fileList = photofile;
            this.chooseFileName = photofile.name;
            fIndex = this.chooseFileName.lastIndexOf(".");
            subString = this.chooseFileName.substring(fIndex, this.chooseFileName.length);
            if (subString === '.xls' || subString === '.xlsx' || subString === '.csv') {
                if (this.choosefile) {
                    if (this.choosefile.files[0].size > 0 && this.choosefile.files[0].size < 4350000) {
                        this.choosefile = baseTarget;
                        this.toggleBox();
                        this.errorUploading = '';
                    } else {
                        this.toggleBoxError();
                        this.errorUploading = 'Base 64 Encoded file is too large.  Maximum size is 4 MB .';
                        console.error('Base 64 Encoded file is too large.  Maximum size is 4 MB .');
                    }
                } else {
                    this.toggleBoxError();
                    this.errorUploading = 'There was an error uploading the file. Please try again'
                    console.error('There was an error uploading the file. Please try again');
                }
            } else {
                this.toggleBoxError();
                this.errorUploading = 'Please upload correct File. File extension should be .csv or .xls'
            }

            reader = new FileReader();
            reader.onload = function () {
                this.fileResult = reader.result;
            };
            reader.readAsDataURL(photofile);
            fileExt = new Array('Bytes', 'KB', 'MB', 'GB');
            while (fileSize > 900) {
                fileSize /= 1024;
                i++;
            }
            exactSize = (Math.round(fileSize * 100) / 100) + ' ' + fileExt[i];
            this.fileName = this.chooseFileName;
            this.fSize = exactSize;
            console.log("File Size-----", fileSize);
            console.log("choosenfileType------", choosenfileType);
            console.log("chooseFileName-------", this.chooseFileName);
        }
    }

    /* Function on file change */
    fileChanged(event) {
        console.log('File change')
        this.fileReader(event.target)
    }

    /* convert string to array */
    proxyToObject(e) {
        return JSON.parse(e)
    }

    changeKeyObjects = (arr, replaceKeys) => {
        return arr.map(item => {
            const newItem = {};
            Object.keys(item).forEach(key => {
                newItem[replaceKeys[key]] = item[[key]];
            });
            return newItem;
        });
    };

    exportCSVFile(){
        const jsonObject = JSON.stringify(this.locationTemplate)
        const result = this.exportToCsv(jsonObject, this.headers)
        const blob = new Blob([result])
        const exportedFilename = this.nameOfLocationFile ? this.nameOfLocationFile+'.csv' :'export.csv'
        if(navigator.msSaveBlob){
            navigator.msSaveBlob(blob, exportedFilename)
        } else if (navigator.userAgent.match(/iPhone|iPad|iPod/i)){
            const link = window.document.createElement('a')
            link.href='data:text/csv;charset=utf-8,' + encodeURI(result);
            link.target="_blank"
            link.download=exportedFilename
            link.click()
        } else {
            const link = document.createElement("a")
            if(link.download !== undefined){
                const url = 'data:text/csv;charset=utf-8,' + encodeURI(result);
                link.setAttribute("href", url)
                link.setAttribute("download", exportedFilename)
                link.style.visibility='hidden'
                document.body.appendChild(link)
                link.click()
                document.body.removeChild(link)
            }
        }
    }

    exportToCsv(objArray, headers) {
        const columnDelimiter = ','
        const lineDelimiter = '\r\n'
        const actualHeaderKey = Object.keys(headers)
        const headerToShow = Object.values(headers) 
        let str = ''
        str+=headerToShow
        str+=lineDelimiter
        const data = typeof objArray !=='object' ? JSON.parse(objArray):objArray

        data.forEach(obj=>{
            let line = ''
            actualHeaderKey.forEach(key=>{
                if(line !== ''){
                    line+=columnDelimiter
                }
                let strItem = obj[key]+''
                line+=strItem? strItem.replace(/,/g, ''):strItem
            })
            str+=line+lineDelimiter
        })
        console.log("str", str)
        return str
    }

     /* Function on file upload */
   async uploadFileLocation(json) {
        var newArray, mLogArray;
        toastEvents(this, 'Please wait while your locations being uploaded.');
        var replaceKeys = {"Name (optional)": "name", "Address": "address", "Range(in feet put 300 if you are not sure)":"range"};
        var moduleKeys = {"Name (optional)": "name", "Address": "address", "Range(in feet put 300 if you are not sure)":"range (ft)"}
        var locationBody = this.proxyToObject(json);
        if (locationBody[0] != null || locationBody[0] !== undefined) {
            var locationKeys = Object.keys(locationBody[0]);
            if (locationKeys.includes("Name (optional)") || locationKeys.includes("Address") || 
                locationKeys.includes("Range(in feet put 300 if you are not sure)")) {
                console.log("replaceKeys-->", replaceKeys)
                newArray = this.changeKeyObjects(locationBody, replaceKeys);
                mLogArray = this.changeKeyObjects(locationBody, moduleKeys);
                newArray.forEach(ob => {
                    ob.userId = this.userTriplogId
                });
                mLogArray.forEach(ob => {
                    ob.userId = this.userTriplogId
                });
                console.log("New Array-->", newArray)
                if (newArray.length > 100) {
                    toastEvents(this, 'Hide');
                    this.toggleBoxError();
                    this.errorUploading = 'You can upload 100 locations at a time.'
                }else{
                    let count;
                    this.attachmentLocation = JSON.stringify(newArray);
                    count = newArray.length;
                    this.mLogLocation = JSON.stringify(mLogArray)
                    this.resultLocation = await uploadLocations(this.attachmentLocation, this.contactId, this.mLogLocation);
                    if (this.resultLocation === 'Success') { 
                        toastEvents(this, 'Hide');
                        modalEvents(this, count);
                    }else{
                        toastEvents(this, 'Hide');
                        this.toggleBoxError();
                        this.errorUploading = 'Some error occured while uploading locations.'
                    }
                    console.log("Result Location", this.resultLocation);
                }
        }else{
            toastEvents(this, 'Hide');
            this.toggleBoxError();
            this.errorUploading = "The file you have uploaded is not valid for location"
        }
        }else{
            toastEvents(this, 'Hide');
            this.toggleBoxError();
            this.errorUploading = "The file you have uploaded is not valid for location"
        }
    }

    uploadFileInChunk() {
        var file = this.fileList, _self = this;
        var reader;
        var maxFileSize = 4350000; //After Base64 Encoding, this is the max file size
        if (file !== undefined) {
            if (file.size <= maxFileSize) {
                this.attachmentName = this.chooseFileName;
                reader = new FileReader();
                reader.onload = function () {
                    var data = this.result;
                    console.log("fileReader", data)
                    this.fileSize = data.length;
                    this.positionIndex = 0;
                    var book = window.XLSX.read(data, {
                        type: 'binary'
                    });
                   book.SheetNames.forEach(function (sheetName) {
                        var XL_row_object = window.XLSX.utils.sheet_to_row_object_array(book.Sheets[sheetName]);
                        var json_object = JSON.stringify(XL_row_object);
                        console.log("json_object", json_object)
                        _self.uploadFileLocation(json_object);
                    })
                }

                reader.onerror = function (event) {
                    console.error("File could not be read! Code " + event.target.error);
                };

                reader.readAsBinaryString(file);
                console.log("this.fileReader", reader)
                //this.fileReader.readAsBinaryString(file);
                // eslint-disable-next-line @lwc/lwc/no-async-operation
            } else {
                console.log()
            }
            console.log("from location file", file);
        } else {
            console.log();
        }
    }

    /* Drag and drop function */
    handleDropFile(event) {
        // prevent default action (open as link for some elements)
        var files;
        console.log('Drop File--', event)
        console.log("files--", event.dataTransfer.files)
        event.preventDefault();
        event.stopPropagation();
        files = event.dataTransfer.files;
        if (files.length === 1) {
            this.template.querySelector('.box').classList.remove('is-dragover');
            this.fileReader(event.dataTransfer)
        } else {
            if (files.length > 1) {
                this.template.querySelector('.box').classList.remove('is-dragover');
                this.fileName = '';
                this.fSize = '';
                this.toggleBoxError();
                this.errorUploading = 'Please select only one file';
            }
        }
    }

    onDrag(event) {
        event.dataTransfer.dropEffect = 'copy';
        event.preventDefault();
        this.template.querySelector('.box').classList.add('is-dragover');
    }

    onDragLeave(event) {
        event.preventDefault();
        this.template.querySelector('.box').classList.remove('is-dragover');
    }

    handleFormSubmit(event) {
        event.preventDefault();
    }
}