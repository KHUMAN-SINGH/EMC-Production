/* eslint-disable no-restricted-globals */
import {
    LightningElement, api, wire, track
} from 'lwc';
// import {
//      openEvents
// } from 'c/utils';
import emcCss from '@salesforce/resourceUrl/EmcCSS';
import logo from '@salesforce/resourceUrl/mBurseCss';
import redirectionURL from '@salesforce/apex/NewAccountDriverController.loginRedirectionADMD';
import getRole from '@salesforce/apex/NewAccountDriverController.getRole';

export default class NavigationMenu extends LightningElement {
    @api driverMenuItem;
    @api driverName;
    @api driverEmail;
    @api profileId;
    @track record;
    roleUser;
    contactId;
    menuLabel;
    initialized = false;
    scroll = false;
    showButtons = false;
    mileageMenu = false;
    manualMenu = false;
    company = logo + '/mburse/assets/mBurse-Icons/mBurse-logo.png';
    companyShort = logo + '/mburse/assets/mBurse-Icons/mBurse-short.png';
    user = emcCss + '/emc-design/assets/images/Icons/SVG/Green/User.svg';
    _originalAdmin = 'Admin Dashboard';
    _originalDriver = 'Driver Dashboard';
    _admin = 'A';
    _driver = 'D';
    _role;
  
    get adminText(){
        return this._admin
    }
  
    set adminText(value){
        this._admin = value;
    }
  
    get driverText(){
        return this._driver
    }
  
    set driverText(value){
            this._driver = value;
    }

  
    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }

  
    handleRedirect(event) {
    //event.stopPropagation();
        let menu = this.template.querySelectorAll(".tooltipText");
        menu.forEach((item) => item.classList.remove('active'))
        const selectedMenu = (event.currentTarget !== undefined ) ? event.currentTarget.dataset.name : event;
        for (let i = 0; i < menu.length; i++) {
          //console.log("Menu---->", selectedMenu , "name---->", menu[i])
            if (selectedMenu === menu[i].dataset.name) {
                menu[i].classList.add('active');
                menu[i].href = `#${selectedMenu}`;
            }
        }
    }
  
    @api toggleStyle(value) {
        let menu = this.template.querySelectorAll(".tooltipText");
        menu.forEach((item) => item.classList.remove('active'))
        const sMenu = value;
        for (let i = 0; i < menu.length; i++) {
            if (sMenu === menu[i].dataset.name) {
                menu[i].classList.add('active');
                menu[i].href = `#${sMenu}`;
            }
        }
    }
  
    redirectToHomePage(){
        // eslint-disable-next-line no-restricted-globals
        var url, path;
        url = location;
        path = url.origin + url.pathname + url.search;
        location.replace(path);
    }
  
    toggleSideBar() {
        const sidebar = this.template.querySelector('.sidebar');
        if(this.showButtons){
            const textAdmin =  this._originalAdmin;
            const textDriver =  this._originalDriver;
            this._admin = (sidebar.className === 'sidebar open') ? textAdmin.substring(0,1) : this._originalAdmin
            this._driver = (sidebar.className === 'sidebar open') ? textDriver.substring(0,1) : this._originalDriver
        }
  
        this.dispatchEvent(
            new CustomEvent("sidebar", {
                detail: sidebar.className
            })
        );
        sidebar.classList.toggle("open");
    }
  
    logOut(){
        const logoutEvent = new CustomEvent('logout', {detail: 'logout'});
        this.dispatchEvent(logoutEvent);
    }

    redirectToDashboard(Id, Role){
        redirectionURL({
            contactId: Id,
            adminTab: Role
        })
        .then((result) => {
            console.log("Result", result);
            let url = location.origin + result;
            window.open(url, '_self');
        })
        .catch((error) => {
            // If the promise rejects, we enter this code block
            console.log(error);
        })
    }
  
    redirectToDriverProfile(){
      // window.location.href = location.origin + '/app/driverProfileDashboard' + location.search;
      this.redirectToDashboard(this.contactId, false)
    }
  
    redirectToProfile(){
        // if(this.profileId === '00e31000001FRDXAA4'){
        //     window.location.href = location.origin + '/app/managerProfileDashboard' + location.search;
        // }else{
        //     window.location.href = location.origin + '/app/adminProfileDashboard' + location.search;
        // }

        this.redirectToDashboard(this.contactId, true)
    }
  
    handleContextMenu = (event) =>{
       // console.log(event)
        event.preventDefault();
    }
  
    // mouseOverLink(){
    //   this.template.querySelector('.menu-wrapper').classList.add('overflow-visible');
    // }
  
    // mouseLeave(){
    //   this.template.querySelector('.menu-wrapper').classList.remove('overflow-visible');
    // }
  
    connectedCallback(){
  
      /*Get logged in user id */
      const idParamValue = this.getUrlParamValue(location.href, "id");
     /* const role = this.getUrlParamValue(location.href, "role")*/
      this.contactId = idParamValue
      getRole({
        contactId: this.contactId
      }).then((result)=>{
        this.roleUser = result
        if(this.roleUser){
            this.showButtons = (this.roleUser === 'Driver/Admin' || this.roleUser === 'Driver/Manager') ? true : false;
            this._originalAdmin = (this.roleUser === 'Driver/Manager') ? 'Manager Dashboard' : 'Admin Dashboard';
            this._admin = (this.roleUser === 'Driver/Manager') ? 'M' : 'A';
        }
        console.log("roleUser##", result)
      }).catch((err)=>{
        console.log("Error from getRole--", err.message)
      })
      /*if(this.profileId){
          this.showButtons = (this.profileId === '00e31000001FRDXAA4' || this.profileId === '00e31000001FRDZAA4') ? true : (role === 'managerdriver') ? true : false;
          this._originalAdmin = (this.profileId === '00e31000001FRDXAA4' || role === 'managerdriver') ? 'Manager Dashboard' : 'Admin Dashboard';
          this._admin = (this.profileId === '00e31000001FRDXAA4' || role === 'managerdriver') ? 'M' : 'A';
      }*/
    }
  
    renderedCallback() {
        const sidebar = this.template.querySelector('.sidebar');
        const menu = this.template.querySelector('.menu-wrapper');
        var tooltips = this.template.querySelectorAll(".tooltip");
        //if(!this.initialized){
            //this.initialized = true
            if(this.roleUser){
                if(this.showButtons){
                    menu.style.maxHeight = 'calc(100% - 198px)';
                    let btn = this.template.querySelector('.admin-btn');
                    let driverBtn = this.template.querySelector('.driver-btn');
                    if(location.pathname === '/app/managerProfileDashboard' || location.pathname === '/app/adminProfileDashboard'){
                        btn.classList.add('active');
                        driverBtn.classList.remove('active');
                    }else{
                        btn.classList.remove('active');
                        driverBtn.classList.add('active');
                    }
                }else{
                    menu.style.maxHeight = 'calc(100% - 105px)';
                }
            }else{
                menu.style.maxHeight = 'calc(100% - 105px)';
            }
        //}
  
        sidebar.addEventListener("mousedown", (evt) => {
            let element = evt.target;
            if (element) {
                if (element.className === "nav-list"  || element.className === 'text-head') {
                    this.dispatchEvent(
                        new CustomEvent("sidebar", {
                            detail: sidebar.className
                        })
                    );
                    sidebar.classList.toggle("open");
                }
            }
        })
  
        menu.addEventListener('scroll', () => {
         if(menu.scrollTop === (menu.scrollHeight - menu.offsetHeight)){
           tooltips.forEach(tooltip => {
              //console.log(tooltip.getBoundingClientRect(), tooltip.parentElement.getBoundingClientRect())
                let v = tooltip.parentElement.getBoundingClientRect().y - tooltip.getBoundingClientRect().y;
                tooltip.style.marginTop = ((v - menu.scrollTop) - tooltip.parentElement.getBoundingClientRect().height) - 35 +"px"; 
                //-35 is the default marginTop value of tooltip
            });
        }else{
          tooltips.forEach(tooltip => {
            //console.log(tooltip.getBoundingClientRect(), tooltip.parentElement.getBoundingClientRect())
              let v = tooltip.parentElement.getBoundingClientRect().y - tooltip.getBoundingClientRect().y;
              tooltip.style.marginTop = (v - menu.scrollTop) - 35 +"px"; 
              //-8 is the default marginTop value of tooltip
          });
        }
      
      });
    }

}