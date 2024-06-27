import { LightningElement, api } from 'lwc';
import getTrips from '@salesforce/apex/ManualEntryController.getTrips';
import resourceImage from '@salesforce/resourceUrl/mBurseCss';

export default class DriverManualEntry extends LightningElement {

    @api contactId;
    @api accountId;
    @api userTriplogId;
    @api mapCountry;
    modalclass = 'slds-modal slds-is-fixed slds-fade-in-open animate__animated animate__fadeInTopLeft';
    headerclass = 'slds-modal__header header-preview hedear-style_class header_style';
    modalcontentstyle = 'slds-modal__content slds-p-left_medium slds-p-right_medium slds-p-bottom_medium slds-p-top_small content_div_scroll , slds-modal__content slds-p-left_medium slds-p-right_medium slds-p-bottom_medium slds-p-top_small overflow-visible';
    styleheader = 'slds-modal__container container_style_1';
    subheaderClass = 'slds-modal__title slds-hyphenate hedear-style_class';
    closebtnclass = 'close-notify';
    mileageConfirmMessage;
    calculatedMileage;
    tripToFillMileage;
    tripOrigin;
    tripDestination;
    showNewTrip = true;
    noTrips = false;
    addTrip = false;
    norecordMessagenew = 'There is no trip data available';
    tableClass = 'slds-table slds-table_cell-buffer slds-table_striped fixed-table';
    headerData = [
        { fieldlabel: 'Trip date', fieldName: 'tripDate', fieldType: 'Date', isUp: false, isDown: false },
        { fieldlabel: 'Origin', fieldName: 'originName', fieldType: 'String', isUp: false, isDown: false },
        { fieldlabel: 'Destination', fieldName: 'destinationName', fieldType: 'String', isUp: false, isDown: false },
        { fieldlabel: 'Mileage', fieldName: 'mileage', fieldType: 'Decimal', isUp: false, isDown: false },
        { fieldlabel: 'Notes', fieldName: 'notes', fieldType: 'String', isUp: false, isDown: false },
        { fieldlabel: 'Tags', fieldName: 'tags', fieldType: 'String', isUp: false, isDown: false }
    ];
    originalTrips = [];
    tripsForOperations = [];
    _tripsToDisplay = [];
    tripDetail = {};
    tripLogApi;
    monthList = [];
    selectedMonth;
    sortDirection = 'desc';
    colName = '';
    colType = '';
    pagePreviousClass = 'cPadding';
    pageNextClass = 'cPadding';
    searchVisible = true;
    isSearchEnable = false;
    searchkey = '';
    /* Pagination */
    totalRecords = 0;
    pageSize = 10;
    totalPages;
    pageNumber = 1;
    pages = [];
    paginate = [];
    shortPaginate = 10;
    moveNext = 3;
    moveBefore = 7;
    maxPage = 10;
    /* Pagination */
    searchIcon = resourceImage + '/mburse/assets/mBurse-Icons/Vector.png';

    @api
    get allTrips() {
        return this._tripsToDisplay;
    }
    set allTrips(member) {
        this._tripsToDisplay = member;
    }

    renderedCallback() {
        var pageBlock = this.template.querySelectorAll('.page-num-block');
        if (pageBlock) {
            pageBlock.forEach(item => {
                if (item.dataset.id) {
                    if (item.dataset.id !== '...') {
                        // eslint-disable-next-line radix
                        if (parseInt(item.dataset.id) === this.pageNumber) {
                            item.classList.add('active')
                        } else {
                            item.classList.remove('active')
                        }
                    } else {
                        item.classList.add('page-num-disabled');
                    }
                }
            })
        }
    }

    connectedCallback() {
        this.createMonthList();
        this.getMonthTrips(this.selectedMonth.value);
    }

    showSpinner() {
        this.dispatchEvent(
            new CustomEvent("spinner", {
              detail: "isShow"
            })
        );
    }

    hideSpinner() {
        this.dispatchEvent(
            new CustomEvent("spinner", {
              detail: "isHide"
            })
        );
    }

    getMonthTrips(month) {
        console.log("month : " + month);
        console.log("this.contactId : " + this.contactId);
        this.showSpinner();
        getTrips({ contactId: this.contactId, selectedMonth: month })
        .then(result => {
            let convRes = JSON.parse(result);
            console.log("Result from getTrips : " + JSON.stringify(convRes));
            if(convRes == 'No trips found for current month.') {
                this.noTrips = true;
                this.hideSpinner();
            } else {
                this.noTrips = false;
                this.tripLogApi = convRes[0].triplogApi;
                convRes.forEach(trip => {
                    if (trip.tripDate) {
                        trip.tripDate = this.convertDate(trip.tripDate)
                    }
                    if (trip.startTime) {
                        trip.startTime = this.convertTime(trip.startTime);
                    }
                    if (trip.endTime) {
                        trip.endTime = this.convertTime(trip.endTime);
                    }
                });

                /* Pagination */
                this.totalRecords = convRes.length;
                /* Pagination */
                this.originalTrips = convRes;
                this.tripsForOperations = convRes;
                this.gotoPage(this.pageNumber, this.tripsForOperations);
                this.setPages();
                this.defaultSort();
                this.hideSpinner();
            }
        })
        .catch(error => {
            console.log("Error from getTrips : " + JSON.stringify(error));
            this.hideSpinner();
            this.noTrips = true;
            let toaster = {
                detail: {
                    type: "error",
                    message: "Something wrong while load you trips."
                }
            }
            this.handleToast(toaster);
        });
    }

    createMonthList() {
        for (let i = 0; i < 3; i++) {
            const today = new Date();
            today.setDate(1);
            today.setMonth(today.getMonth() - i);
            const month = today.getMonth() + 1;
            const year = today.getFullYear();
            const monthName = today.toLocaleString('default', { month: 'long' });
            let temp = {
                id: monthName,
				label: monthName,
				value: (month < 10 ? '0' : '') + month + '-' + year
            }
            this.monthList.push(temp);
        }
        this.selectedMonth = this.monthList[0];
    }

    convertDate(date) {
        let dYear = parseFloat(date.split('-')[0]);
        let convDate = date.split('-')[1] + '/' + date.split('-')[2] + '/' + (dYear % 100);
        return convDate;
    }

    convertTime(time) {
        let tripStartTime = new Date(time);
        let convStartTime = tripStartTime.toLocaleTimeString("en-US", {
          timeZone: "America/Panama",
          hour: "2-digit",
          minute: "2-digit",
        });
        return convStartTime;
    }

    handleToast(event) {
        this.dispatchEvent(
            new CustomEvent("toast", {
                detail: event.detail
            })
        );
    }

    defaultSort() {
        this.colName = 'tripDate';
        this.colType = 'Date';
        this.sortDirection = 'desc';
        this.sortDataEvent();
    }

    handleSort(event) {
        this.colName = event.target.dataset.name;
        this.colType = event.currentTarget.dataset.sort;
        this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
        this.sortDataEvent();
    }

    sortDataEvent() {
        let isReverse = this.sortDirection === 'asc' ? 1 : -1;
        let dataToSort = this.tripsForOperations;
        let sortedData = dataToSort.slice().sort((a, b) => {
            if (this.colType === "Decimal") {
                a[this.colName] = (typeof a[this.colName] === 'string') ? ((a[this.colName].indexOf('$') > -1) ? a[this.colName].replace(/\$/g, "") : a[this.colName]) : a[colName];
                b[this.colName] = (typeof b[this.colName] === 'string') ? ((b[this.colName].indexOf('$') > -1) ? b[this.colName].replace(/\$/g, "") : b[this.colName]) : b[colName];
                a = (a[this.colName] == null || a[this.colName] === 'null') ? '' : parseFloat(a[this.colName])
                b = (b[this.colName] == null || b[this.colName] === 'null') ? '' : parseFloat(b[this.colName])
                return a > b ? 1 * isReverse : -1 * isReverse;
            }
            if (this.colType === "Integer") {
                a = (a[this.colName] == null || a[this.colName] === 'null') ? '' : parseInt(a[this.colName])
                b = (b[this.colName] == null || b[this.colName] === 'null') ? '' : parseInt(b[this.colName])
                return a > b ? 1 * isReverse : -1 * isReverse;
            }
            if (this.colType === "Date") {
                a = (a[this.colName] == null || a[this.colName] === '') ? null : new Date(a[this.colName].toLowerCase())
                b = (b[this.colName] == null || b[this.colName] === '') ? null : new Date(b[this.colName].toLowerCase())
                return a > b ? 1 * isReverse : -1 * isReverse;
            }
            a = (a[this.colName] == null || a[this.colName] === '') ? '' : (typeof a[this.colName] === 'object') ? a[this.colName].join(',').toLowerCase() : a[this.colName].toLowerCase();
            b = (b[this.colName] == null || b[this.colName] === '') ? '' : (typeof b[this.colName] === 'object') ? b[this.colName].join(',').toLowerCase() : b[this.colName].toLowerCase();
            return a > b ? 1 * isReverse : -1 * isReverse;
        });
        this.tripsForOperations = sortedData;
        this.totalRecords = sortedData.length;
        this.adjustSortIcons(this.colName);
        this.gotoPage(this.pageNumber, this.tripsForOperations);
        this.setPages();
    }

    adjustSortIcons(colName) {
        this.headerData.forEach(element => {
            element.isUp = false;
            element.isDown = false;
            if(element.fieldName == colName) {
                if(this.sortDirection == 'asc') {
                    element.isUp = true;
                } else {
                    element.isDown = true;
                }
            }
        });
    }

    handleSearchChange(event) {
        this.searchkey = event.target.value;
        this.isSearchEnable = this.searchkey == "" ? false : true;
        let recordsToDisplay = [];

        for (const key in this.originalTrips) {
            if (Object.hasOwnProperty.call(this.originalTrips, key)) {
                let res;
                for (const item in this.originalTrips[key]) {
                    if (Object.hasOwnProperty.call(this.originalTrips[key], item)) {
                        const element = this.originalTrips[key][item];
                        if (element) {
                            res = element.toString().toLowerCase().includes(this.searchkey.toLowerCase());
                            if (res) {
                                recordsToDisplay.push(this.originalTrips[key]);
                                break;
                            }
                        }
                    }
                }
            }
        }
        this.totalRecords = recordsToDisplay.length;
        this.tripsForOperations = recordsToDisplay;
        this.gotoPage(this.pageNumber, this.tripsForOperations);
        this.setPages();
        if(this.colName !== '') {
            this.sortDataEvent();
        }
    }

    handleClearInput() {
        this.searchkey = '';
        this.isSearchEnable = false;
        let recordsToDisplay = this.originalTrips;
        this.totalRecords = recordsToDisplay.length;
        this.tripsForOperations = recordsToDisplay;
        this.gotoPage(this.pageNumber, this.tripsForOperations);
        this.setPages();
        if(this.colName !== '') {
            this.sortDataEvent();
        }
    }

    gotoPage(pageNumber, source) {
        if(source.length > 0) {
            var recordStartPosition, recordEndPosition;
            var i, arrayElement; // Loop helpers
            var maximumPages = Math.ceil(this.totalRecords / this.pageSize);

            // Validate that desired page number is available
            if (pageNumber > maximumPages || pageNumber < 0) {
                this.pageNumber = 1;
                return;
            }

            // Reenable both buttons
            this.disabledPreviousButton = false;
            this.disabledNextButton = false;
            this.pageNextClass = 'cPadding';
            this.pagePreviousClass = (!this.disabledPreviousButton) ? 'cPadding' : 'cPadding disabled';
            // Is data source valid?
            if (source.length > 0) {

                // Empty the data source used
                // eslint-disable-next-line @lwc/lwc/no-api-reassignments
                this._tripsToDisplay = [];

                // Start the records at the page position
                recordStartPosition = (pageNumber - 1) * this.pageSize;

                // End the records at the record start position with an extra increment for the page size
                recordEndPosition = (pageNumber * this.pageSize);

                // Loop through the selected page of records
                for (i = recordStartPosition; i < recordEndPosition; i++) {
                    arrayElement = source[i];
                    if (arrayElement) {
                        this._tripsToDisplay.push(arrayElement);
                    }
                }
                this.dynamicBinding(this._tripsToDisplay, this.headerData);
                this.dynamicBinding(this.originalTrips, this.headerData);
                this.dynamicBinding(this.tripsForOperations, this.headerData);
                this.noTrips = false;
                console.log("After operation trips : " + JSON.stringify(this.allTrips));
                this.pageNumber = pageNumber;
                if (maximumPages === this.pageNumber) {
                    this.disabledNextButton = true;
                    this.pageNextClass = 'cPadding disabled'
                }
                // If current page is the first page then disable the previous button
                if (this.pageNumber === 1) {
                    this.disabledPreviousButton = true;
                    this.pagePreviousClass = 'cPadding disabled'
                }
            }
        } else {
            this._tripsToDisplay = [];
            this.noTrips = true;
        }
    }
    setPages() {
        this.pages = [];
        this.paginate = [];
        for (let index = 1; index <= Math.ceil(this.totalRecords / this.pageSize); index++) {
            this.pages.push(index);
            this.paginate.push(index);
        }
        if (this.pages.length > 10) {
            this.mapPages();
        }
    }
    mapPages() {
        var pagelen = this.pages.length;
        var indexlen = pagelen - (this.maxPage + 1);
        if (this.pages.length > this.maxPage) {
            this.pages.splice(this.maxPage, indexlen, "...");
        }
    }
    onPrev = () => {
        var pageNo = this.pageNumber - 1;
        this.handleButtonPrevious();
        if (this.paginate.length > this.shortPaginate) {
            if (pageNo < this.paginate.length) {
                if (pageNo > 10) {
                    this.nextPrevChange(pageNo);
                } else {
                    this.noPageChange(pageNo);
                }
            }
        }
    }
    handleButtonPrevious() {
        var nextPage = this.pageNumber - 1;
        var maxPages = Math.ceil(this.totalRecords / this.pageSize);
        var pageBlock = this.template.querySelectorAll('.page-num-block');
        if (nextPage > 0 && nextPage <= maxPages) {
            pageBlock.forEach(item => {
                if (item.dataset.id) {
                    // eslint-disable-next-line radix
                    if (parseInt(item.dataset.id) === nextPage) {
                        item.classList.add('active')
                    } else {
                        item.classList.remove('active')
                    }
                }
            })
            this.gotoPage(nextPage, this.tripsForOperations);
        }
    }
    onNext = () => {
        var pageNo = this.pageNumber + 1;
        this.handleButtonNext()
        //  console.log(this.paginate.length, pageNo)
        if (this.paginate.length > this.shortPaginate) {
            if (pageNo > 10) {
                this.nextPrevChange(pageNo);
            }
        }
    }
    handleButtonNext() {
        var nextPage = this.pageNumber + 1;
        var maxPages = Math.ceil(this.totalRecords / this.pageSize);
        var pageBlock = this.template.querySelectorAll('.page-num-block');
        //console.log("HANDLE NEXT");
        if (nextPage > 0 && nextPage <= maxPages) {
            pageBlock.forEach(item => {
                if (item.dataset.id) {
                    // eslint-disable-next-line radix
                    if (parseInt(item.dataset.id) === nextPage) {
                        item.classList.add('active')
                    } else {
                        item.classList.remove('active')
                    }
                }
            })
            this.gotoPage(nextPage, this.tripsForOperations);
        }
    }
    nextPrevChange(index) {
        var len = this.paginate.length;//46
        if (index !== len) {
            this.pages = this.paginate.slice();
            let startP = index + this.moveNext;
            let skiplen = len - (startP + 1);
            let inclen = index - this.moveBefore;
            if (startP < len) {
                this.pages.splice(startP, skiplen, '...');
                this.pages.splice(1, inclen, '...');
            } else {
                this.pages.splice(1, inclen, '...');
            }
            //console.log("pages",JSON.stringify(this.pages));
        }
    }
    noPageChange(index) {
        this.maxPage = 10;
        let pagelen = this.paginate.length;
        let indexlen = pagelen - (this.maxPage + 1)
        if (index === this.maxPage) {
            this.pages = this.paginate.slice();
            this.pages.splice(this.maxPage, indexlen, '...');
        }
    }
    onPageClick = (e) => {
        var pageBlock = this.template.querySelectorAll('.page-num-block');
        var nowPage = parseInt(e.target.dataset.id, 10);
        var maxPages = Math.ceil(this.totalRecords / this.pageSize);
        var next;
        if (this.paginate.length > 10) {
            if (nowPage !== this.paginate.length) {
                if (nowPage === this.maxPage) {
                    next = nowPage
                    this.paginateChange(nowPage);
                } else {
                    this.reverseEndPaginate(nowPage, next);
                }
            } else {
                this.onLastPage(nowPage);
            }
        }

        if (nowPage > 0 && nowPage <= maxPages) {
            pageBlock.forEach(item => {
                if (item.dataset.id) {
                    // eslint-disable-next-line radix
                    if (parseInt(item.dataset.id) === nowPage) {
                        item.classList.add('active')
                    } else {
                        item.classList.remove('active')
                    }
                }
            })
            this.gotoPage(nowPage, this.tripsForOperations);
        }
        // console.log("pagecount", nowPage, this.maxPages)
    }
    paginateChange(index) {
        var totalpage = this.paginate.length;
        if (index !== totalpage) {
            this.pages = this.paginate.slice();
            this.maxPage = index + this.moveNext;
            this.minPage = index - this.moveBefore;
            let skip = totalpage - (this.maxPage + 1)
            if (this.maxPage !== totalpage && this.maxPage < totalpage) {
                this.pages.splice(this.maxPage, skip, '...');
                this.pages.splice(1, this.minPage, '...');
            } else {
                this.pages.splice(1, this.minPage, '...');
            }
        }
        //console.log(this.pages);
    }
    reverseEndPaginate(index, nextClick) {
        if (nextClick === undefined) {
            nextClick = this.paginate.length;
        }
        if (index < nextClick) {
            if (index >= 10) {
                //  console.log("inside paginateChange")
                this.paginateChange(index);
            } else {
                this.maxPage = 10;
                let pagelen = this.paginate.length;
                let indexlen = pagelen - (this.maxPage + 1)
                this.pages = this.paginate.slice();
                this.pages.splice(this.maxPage, indexlen, '...');
            }
        } else {
            if (index === 1) {
                this.maxPage = 10;
                let pagelen = this.paginate.length;
                let indexlen = pagelen - (this.maxPage + 1)
                this.pages = this.paginate.slice();
                this.pages.splice(this.maxPage, indexlen, '...');
            }

        }
        //  console.log('reverse:-', index, nextClick);
    }
    onLastPage(index) {
        let pageSkip = index - 10;
        this.pages = this.paginate.slice();
        this.pages.splice(1, pageSkip, '...');
    }
    // paginateHelper() {
    //     this._tripsToDisplay = [];
    //     this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
    //     if (this.pageNumber <= 1) {
    //         this.pageNumber = 1;
    //     } else if (this.pageNumber >= this.totalPages) {
    //         this.pageNumber = this.totalPages;
    //     }
    //     for (let i = (this.pageNumber - 1) * this.pageSize; i < this.pageNumber * this.pageSize; i++) {
    //         if (i === this.totalRecords) {
    //             break;
    //         }
    //         this._tripsToDisplay.push(this.originalTrips[i]);
    //     }
    //     console.log("this._tripsToDisplay : " + this._tripsToDisplay.length);
    //     console.log('Total pages : ' + this.totalPages);
    // }

    handleMonthChange(event) {
        this.searchkey = "";
        this._tripsToDisplay = [];
        this.originalTrips = [];
        this.tripsForOperations = [];
        let tempMonth = this.monthList.find(month => month.label == event.detail.value);
        this.selectedMonth = tempMonth;
        this.pageNumber = 1;
        this.getMonthTrips(this.selectedMonth.value);
    }

    handleCreateTrip() {
        if(this.addTrip == true) {
            let eventObj = {
                detail: { tripType : true }
            };
            this.handleCloseTrip(eventObj);
        } else {
            let d = new Date();
            let day = d.getDate();
            let month = d.getMonth() + 1;
            let year = d.getFullYear() % 100;
            let hours = d.getHours();
            let minutes = d.getMinutes();
            let ampm = hours >= 12 ? 'PM' : 'AM';
            hours = hours % 12;
            hours = hours ? hours : 12;
            this.tripDetail = {
                tripDate: (month < 10 ? '0' : '') + month + '/' + (day < 10 ? '0' : '') + day + '/' + (year < 10 ? '0' : '') + year,
                startTime: (hours < 10 ? "0" : "") + hours + ":" + (minutes < 10 ? "0" : "") + minutes + " " + ampm,
                endTime: '',
                origin: '',
                destination: '',
                originName: '',
                destinationName: '',
                mileage: '',
                tags: '',
                notes: '',
                isEditMode: true
            };
            this.showNewTrip = false;
            this.addTrip = true;
        }
    }

    handleTripAccordian(event) {
        let tripId = event.currentTarget.dataset.id;
        console.log('tripId : ' + tripId);
        this._tripsToDisplay = this._tripsToDisplay.map(record => {
            if(record.id === tripId) {
                return { ...record, isEditMode: !record.isEditMode };
            }
            return record;
        });
        this.originalTrips = this.originalTrips.map(record => {
            if(record.id === tripId) {
                return { ...record, isEditMode: !record.isEditMode };
            }
            return record;
        });
        this.tripsForOperations = this.tripsForOperations.map(record => {
            if(record.id === tripId) {
                return { ...record, isEditMode: !record.isEditMode };
            }
            return record;
        });
        this.tableClass = 'slds-table slds-table_cell-buffer slds-table_striped fixed-table';
        console.log('row -- ' + event.currentTarget.rowIndex);
        // if(event.currentTarget.rowIndex % 2 != 0) {
        //     event.currentTarget.style.setProperty('border', '1px solid #E4E4E4', 'important');
        //     event.currentTarget.style.setProperty('border-radius', '10px', 'important');
        //     // let allChild = event.currentTarget.childNodes;
        //     // for (let i = 0; i < allChild.length; i++) {
        //     //     allChild[i].style.setProperty('border', '1px solid #E4E4E4', 'important');
        //     //     if(i == 0) {
        //     //         allChild[i].style.setProperty('border-left', '1px solid #E4E4E4', 'important');
        //     //         allChild[i].style.setProperty('border-right', 'none', 'important');
        //     //         allChild[i].style.setProperty('border-top-left-radius', '10px', 'important');
        //     //         allChild[i].style.setProperty('border-bottom-left-radius', '10px', 'important');
        //     //     } else if(i == (allChild.length - 1)) {
        //     //         allChild[i].style.setProperty('border-right', '1px solid #E4E4E4', 'important');
        //     //         allChild[i].style.setProperty('border-left', 'none', 'important');
        //     //         allChild[i].style.setProperty('border-top-right-radius', '10px', 'important');
        //     //         allChild[i].style.setProperty('border-bottom-right-radius', '10px', 'important');
        //     //     } else {
        //     //         allChild[i].style.setProperty('border-left', 'none', 'important');
        //     //         allChild[i].style.setProperty('border-right', 'none', 'important');
        //     //     }
        //     // }
        // }
    }

    handleCloseTrip(event) {
        console.log("event in main compo : " + JSON.stringify(event.detail));
        let isNewTrip = event.detail.tripType;
        if(isNewTrip == true) {
            this.showNewTrip = true;
            this.tableClass = 'slds-table slds-table_cell-buffer slds-table_striped fixed-table';
            this.addTrip = false;
        } else {
            let idOfTrip = event.detail.tripId;
            // let idOfTrip = event.currentTarget.dataset.id;
            this._tripsToDisplay = this._tripsToDisplay.map(record => {
                if(record.id == idOfTrip) {
                    return { ...record, isEditMode: false };
                }
                return record;
            });
            this.originalTrips = this.originalTrips.map(record => {
                if(record.id === idOfTrip) {
                    return { ...record, isEditMode: !record.isEditMode };
                }
                return record;
            });
            this.tripsForOperations = this.tripsForOperations.map(record => {
                if(record.id === idOfTrip) {
                    return { ...record, isEditMode: !record.isEditMode };
                }
                return record;
            });
        }
    }

    handleCloseModal() {}

    distancePopUp(event) {
        this.calculatedMileage = event.detail.mil;
        this.tripToFillMileage = event.detail.tripId;
        this.tripOrigin = event.detail.origin;
        this.tripDestination = event.detail.destination;
            this.mileageConfirmMessage = 'Do you want to apply to the trip?';
        if (this.template.querySelector('c-user-profile-modal')) {
            this.template.querySelector('c-user-profile-modal[data-id="mileageCalc"]').show();
        }
    }

    handleModalCancel() {
        if (this.template.querySelector('c-user-profile-modal')) {
            this.template.querySelector('c-user-profile-modal[data-id="mileageCalc"]').hide();
        }
    }

    handleModalOk() {
        this.template.querySelector(`c-trip-accordian-view[data-id=${this.tripToFillMileage}]`).fillMileage(this.calculatedMileage);
        this.template.querySelector('c-user-profile-modal[data-id="mileageCalc"]').hide();
    }

    dynamicAddLoc(event) {
        let allAccordians = this.template.querySelectorAll('c-trip-accordian-view');
        allAccordians.forEach(element => {
            element.dynamicLocAdd(event.detail.location);
        });
        this.template.querySelector(`c-trip-accordian-view[data-id=${event.detail.tripId}]`).fillLocation(event.detail);
    }

    dynamicUpdtLoc(event) {
        let allAccordians = this.template.querySelectorAll('c-trip-accordian-view');
        allAccordians.forEach(element => {
            element.dynamicLocUpdt(event.detail);
        });
    }

    dynamicAddTrip(event) {
        console.log('Trip at addition : ' + JSON.stringify(event.detail.tripNew));
        let newTrip = {
            id: event.detail.tripNew.Id,
            tags: event.detail.tripNew.Tag__c == null ? '' : event.detail.tripNew.Tag__c,
            notes: event.detail.tripNew.Notes__c == null ? '' : event.detail.tripNew.Notes__c,
            mileage: event.detail.tripNew.EMP_Mileage__c.toString(),
            startTime: '',
            endTime: '',
            origin: event.detail.tripNew.Trip_Origin__c,
            destination: event.detail.tripNew.Trip_Destination__c,
            originName: event.detail.tripNew.Original_Origin_Name__c,
            destinationName: event.detail.tripNew.Original_Destination_Name__c,
            fromLat: event.detail.tripNew.From_Location__Latitude__s,
            fromLong: event.detail.tripNew.From_Location__Longitude__s,
            toLat: event.detail.tripNew.To_Location__Latitude__s,
            toLong: event.detail.tripNew.To_Location__Longitude__s,
            timeZone: event.detail.tripNew.TimeZone__c,
            wayPoints: event.detail.tripNew.Way_Points__c,
            triplogApi: this.tripLogApi
        };

        newTrip.tripDate = this.convertDate(event.detail.tripNew.Trip_Date__c);
        if (event.detail.tripNew.StartTime__c != null) {
            newTrip.startTime = this.convertTime(event.detail.tripNew.StartTime__c);
        }
        if (event.detail.tripNew.EndTime__c != null) {
            newTrip.endTime = this.convertTime(event.detail.tripNew.EndTime__c);
        }

        let isNewTrip = event.detail.tripType;
        if(isNewTrip == true) {
            this.noTrips = false;
        }

        this._tripsToDisplay.push(newTrip);
        this.originalTrips.push(newTrip);
        this.tripsForOperations.push(newTrip);
        // this.dynamicBinding(this._tripsToDisplay, this.headerData);
        // this.dynamicBinding(this.originalTrips, this.headerData);
        // this.dynamicBinding(this.tripsForOperations, this.headerData);
        // this._tripsToDisplay = JSON.parse(JSON.stringify(this._tripsToDisplay));

        this.gotoPage(this.pageNumber, this.tripsForOperations);
        this.setPages();
        this.defaultSort();
        console.log("After addition trips : " + JSON.stringify(this.allTrips));
    }

    dynamicUpdateTrip(event) {
        console.log('Trip at updation : ' + JSON.stringify(event.detail));
        let updtTrip = {
            id: event.detail.Id,
            tags: event.detail.Tag__c == null ? '' : event.detail.Tag__c,
            notes: event.detail.Notes__c == null ? '' : event.detail.Notes__c,
            mileage: event.detail.EMP_Mileage__c.toString(),
            startTime: '',
            endTime: '',
            origin: event.detail.Trip_Origin__c,
            destination: event.detail.Trip_Destination__c,
            originName: event.detail.Original_Origin_Name__c,
            destinationName: event.detail.Original_Destination_Name__c,
            fromLat: event.detail.From_Location__Latitude__s,
            fromLong: event.detail.From_Location__Longitude__s,
            toLat: event.detail.To_Location__Latitude__s,
            toLong: event.detail.To_Location__Longitude__s,
            timeZone: event.detail.TimeZone__c,
            wayPoints: event.detail.Way_Points__c,
            triplogApi: this.tripLogApi
        };

        updtTrip.tripDate = this.convertDate(event.detail.Trip_Date__c);
        if (event.detail.StartTime__c != null) {
            updtTrip.startTime = this.convertTime(event.detail.StartTime__c);
        }
        if (event.detail.EndTime__c != null) {
            updtTrip.endTime = this.convertTime(event.detail.EndTime__c);
        }

        let indexOfDisplayTrips = this._tripsToDisplay.findIndex(record => record.id == updtTrip.id);
        if (indexOfDisplayTrips !== -1) {
          this._tripsToDisplay[indexOfDisplayTrips] = updtTrip;
        }
        let indexOfOriginalTrips = this.originalTrips.findIndex(record => record.id == updtTrip.id);
        if (indexOfOriginalTrips !== -1) {
          this.originalTrips[indexOfOriginalTrips] = updtTrip;
        }
        let indexOfOperationTrips = this.tripsForOperations.findIndex(record => record.id == updtTrip.id);
        if (indexOfOperationTrips !== -1) {
          this.tripsForOperations[indexOfOperationTrips] = updtTrip;
        }
        this.dynamicBinding(this._tripsToDisplay, this.headerData);
        this.dynamicBinding(this.originalTrips, this.headerData);
        this.dynamicBinding(this.tripsForOperations, this.headerData);
        this._tripsToDisplay = JSON.parse(JSON.stringify(this._tripsToDisplay));
        console.log("After updation trips : " + JSON.stringify(this.allTrips));
    }

    dynamicBinding(trips, header) {
        trips.forEach(trip => {
            let keyFields = [];
            header.forEach(column => {
                let tempObj = {
                    key: column.fieldName,
                    type: column.fieldType,
                    isTooltip: (column.fieldName == 'originName' || column.fieldName == 'destinationName') ? true : false,
                    tooltipText : ((column.fieldName == 'originName' || column.fieldName == 'destinationName') ? (column.fieldName == 'originName' ? trip.origin : trip.destination) : "")
                };
                if(trip.hasOwnProperty(column.fieldName)) {
                    if(column.fieldName == 'mileage') {
                        tempObj.value = (parseFloat(trip[column.fieldName]).toFixed(2)).toString();
                    } else if(column.fieldName == 'originName' || column.fieldName == 'destinationName') {
                        if(trip[column.fieldName] != '') {
                            tempObj.value = trip[column.fieldName];
                        } else {
                            tempObj.value = column.fieldName == 'originName' ? trip.origin : trip.destination;
                        }
                    } else {
                        tempObj.value = trip[column.fieldName];
                    }
                } else {
                    tempObj.value = '';
                }
                keyFields.push(tempObj);
            });
            trip.keyFields = keyFields;
            trip.isEditMode = trip.isEditMode === true;
        });
    }

}