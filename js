import { LightningElement, wire, track, api } from 'lwc';
import showHistoryList from "@salesforce/apex/MLQ_QuoteCreatorLWC.getQuoteHistory";
import mlqOfferWaveOWS from '@salesforce/label/c.MLQ_Offer_Wave_OWS';
import mlqOfferSWUniEvc from '@salesforce/label/c.MLQ_Offer_SWUniEvc';
import mlqOfferIDE from '@salesforce/label/c.MLQ_Offer_IDE';
import mlqOfferIDEPlus from '@salesforce/label/c.MLQ_Offer_IDE_Plus';
import mlqOfferWaveCP from '@salesforce/label/c.MLQ_Offer_Wave_CP';
import mlqSWElineTLS from '@salesforce/label/c.MLQ_SWEline_TLS';
import mlqWavelengthSolutions from '@salesforce/label/c.MLQ_Wavelength_Solutions';
import mlqPrivateLine from '@salesforce/label/c.MLQ_Private_Line'; //Added By Manav || PL MLQ changes || 15-Mar-2022
import mlqSWEline from '@salesforce/label/c.MLQ_SWEline'; // Added by Pushpendra | Ethernet International 
import mlqCapacityCheckMessage from '@salesforce/label/c.MLQ_CapacityCheckMessage'; // Added by Pushpendra | Ethernet International
import mlqPip from '@salesforce/label/c.MLQ_PIP_Legacy_Product';

export default class VpsSummaryModelLWC extends LightningElement {

  //Boolean tracked variable to indicate if modal is open or not default value is false as modal is closed when page is loaded
  @track isModalOpen = true;
  @track quoteHistDetails;
  @track quoteHistDetailsSliced;
  @track GenICBFlow = false;
  @track toLocation = false;
  @track productIDE;
  @track productSWUE;
  @track showSWUEProduct = false;
  @track showIDEProduct = false;
  @track showOWSProdOffering = false;
  @track showTLSProduct = false;
  @track showServiceType = false;
  @track showUniAccess = false;
  @track showAccess = false;
  @track showPortConfig = false;
  @track isDDoS = false; //Nikhil
  showEssentialsSpeed = false;
  showExpectedCarrier = false;
  showLocationDetail = false;
  @track showTargetPrice = false;
  @api quote;
  @api verizonLegalEntity; // Added by Pushpendra | Shop International
  @track showDiversity = false; // Added by Pushpendra | Shop International
  @track showIDPlusProduct = false; // Added by Pushpendra | Shop International
  @track isRecommended = false; //Added by suveatha | Shop International
  speedDisplayText;
  @api isVettingEnabledModel = false;
  @track isCapacityCheck = false;
  @track zoneValue;
  @track zoneValueAccess;
  @track isIOFSpeed = false;
  @track constNRCval = '';
  @track locationDetailsVal = '';
  @track showPlProduct = false; //Added By Manav || PL MLQ changes || 15-Mar-2022
  @track isNotDALProduct = false; //Added By Sakthi Brindha || PL DAL MLQ changes || 22-Apr-2022
  @track showIntSWUEProduct = false; //Added by Pushpendra | Ethernet International
  @track showNNIHUBLocation = false; //Added by Pushpendra | Ethernet International
  @track showVLEForSWUE = false; //Added by Pushpendra | Ethernet International
  @track showVLEForIDPlus = false; //Added by Pushpendra | Ethernet International
  @track showGeographicType = false; //Added by Pushpendra | Ethernet International
  @track showCapacityRequiredMsg = false; //Added by Pushpendra | Ethernet International
  @track showPIPProduct = false;
  @track ProviderValue;
  @track showNid = false;
  showToDS = false;//For Additional Features
  showFromDS = false;//For Additional Features
  toatlMRC;//For Currency Changes
  totalNRC;//For Currency Changes
  targetMRC;//For Currency Changes
  targetNRC;//For Currency Changes
  lable = {
    mlqOfferWaveOWS,
    mlqOfferSWUniEvc,
    mlqOfferIDE,
    mlqOfferIDEPlus,
    mlqOfferWaveCP,
    mlqWavelengthSolutions,
    mlqSWElineTLS,
    mlqPrivateLine, //Added By Manav || PL MLQ changes || 15-Mar-2022
    mlqSWEline, //Added by Pushpendra | Ethernet International
    mlqCapacityCheckMessage, //Added by Pushpendra | Ethernet International
    mlqPip
  }
  //For Currency Changes
  formatCurrency(currencyType, currencyValue) {
    return currencyValue.includes(".") ? (new Intl.NumberFormat('en-US', { style: 'currency', currency: currencyType }).format((currencyValue.split(".")[0]).replaceAll(',', ''))).split(".")[0] + '.' + ((currencyValue.split(".")[1] && currencyValue.split(".")[1].length == 1) ? currencyValue.split(".")[1] + '0' : currencyValue.split(".")[1]) : new Intl.NumberFormat('en-US', { style: 'currency', currency: currencyType }).format(currencyValue);

  }
  connectedCallback() {
    console.log('this.quote--- ' + JSON.stringify(this.quote));
    //For Currency Changes
    let currencySelected = this.quote.currencySelected ? this.quote.currencySelected : 'USD';
    if (this.quote.prices) {
      if (this.quote.prices.mrc) {
        this.toatlMRC = this.formatCurrency(currencySelected, this.quote.prices.mrc);
      }
      if (this.quote.prices.targetMRC) {
        this.targetMRC = this.formatCurrency(currencySelected, this.quote.prices.targetMRC);
      }
      if (this.quote.prices.nrc) {
        this.totalNRC = this.formatCurrency(currencySelected, this.quote.prices.nrc);
      }
      if (this.quote.prices.targetNRC) {
        this.targetNRC = this.formatCurrency(currencySelected, this.quote.prices.targetNRC);
      }
    }
    //For Currency Changes
    //For Additional Features
    if(this.quote.productAttributes.tpCrossConnectFrom == 'Yes'){
      this.showFromDS = true;
    }
    if(this.quote.productAttributes.tpCrossConnectTo == 'Yes'){
       this.showToDS = true;
    }
    //For Additional Features
    //capacityCheck capacityCheck
    if (this.quote.productAttributes.capacityCheck === 'No') {
      this.isCapacityCheck = true;
    } else {
      this.isCapacityCheck = false;
    }
    if (this.quote.prices.constNRC) {
      this.constNRCval = this.quote.prices.constNRC.replace(/\d(?=(\d{3})+\.)/g, '$&,');
      //For Currency Changes
      this.constNRCval = this.formatCurrency(currencySelected, this.constNRCval);
    }
    // product
    if (this.quote.productAttributes.productOffering != null) {
      if (this.quote.productAttributes.productOffering === this.lable.mlqOfferSWUniEvc) {
        this.productSWUE = 'Switched E-Line UNI EVC';
        this.showSWUEProduct = true;
        //Start - Added by Pushpendra | Ethernet International
        if(this.quote.productAttributes.productFamily === this.lable.mlqSWEline){
          this.showIntSWUEProduct = true;
          console.log('this.quote.tolocation.value --'+this.verizonLegalEntity);
          if(this.quote.tolocation.value){
            this.showNNIHUBLocation = true;
          }
          if(this.verizonLegalEntity && this.verizonLegalEntity != '--Select One--' && this.verizonLegalEntity != ''){
            this.showVLEForSWUE = true;
          }
          if(this.quote.accessRecResponse.geographicType){
            this.showGeographicType = true;
          }
          //Need to add if statement for capacity check msg
          if(this.quote.accessRecResponse.capacityCheckQualified=='Yes' && this.quote.locationType=='International'){ // Added by Ashish || Ethernet International || 29/7/22
            this.showCapacityRequiredMsg = true;
          }//End
         
        }
        //End - Added by Pushpendra | Ethernet International
        if (this.quote.productAttributes.evcSpeed && this.quote.productAttributes.evcSpeed != undefined) {
          this.speedDisplayText = 'EVC: ' + this.quote.productAttributes.evcSpeed + ' ';
        }
        if (this.quote.productAttributes.derivedUNISpeed && this.quote.productAttributes.derivedUNISpeed != undefined) {
          this.speedDisplayText = this.speedDisplayText + 'UNI: ' + this.quote.productAttributes.derivedUNISpeed + ' ';
        }
        if (this.quote.productAttributes.productFamily === this.lable.mlqSWElineTLS && this.quote.productAttributes.portAndAccessSpeed && this.quote.productAttributes.portAndAccessSpeed != undefined) {
          this.speedDisplayText = this.speedDisplayText + 'UNI: ' + this.quote.productAttributes.portAndAccessSpeed + ' ';
        }
        else if (this.quote.productAttributes.portAndAccessSpeed && this.quote.productAttributes.portAndAccessSpeed != undefined) {
          this.speedDisplayText = this.speedDisplayText + 'Access: ' + this.quote.productAttributes.portAndAccessSpeed + ' ';
        }
      }
      else if (this.quote.productAttributes.productOffering === this.lable.mlqOfferIDE || this.quote.productAttributes.productOffering === this.lable.mlqOfferIDEPlus) {
        this.showIDEProduct = true;
        if(this.quote.accessRecResponse.capacityCheckQualifiedID =='Yes' && this.quote.productAttributes.productOffering === this.lable.mlqOfferIDEPlus ){ // Added by Ashish || Ethernet International || 29/7/22
          this.showCapacityRequiredMsg = true;
         
        }//End
      }
      else if (this.quote.productAttributes.productFamily === this.lable.mlqWavelengthSolutions) {
        this.isVettingEnabledModel;
        this.showOWSProdOffering = true;
      }
      //Added By Manav || PL MLQ changes - added below else if || 15-Mar-2022
      else if (this.quote.productAttributes.productFamily === this.lable.mlqPrivateLine) {
        this.showPlProduct = true;
        // Start - Added by Sakthi Brindha | MLQ PL DAL - 22- Apr-2022
        if (this.quote.productAttributes.productOffering !== 'Dedicated Access Line') {
          this.isNotDALProduct = true;
        }
        // End - Added by Sakthi Brindha | MLQ PL DAL - 22- Apr-2022
      }
      else if (this.quote.productAttributes.productFamily === this.lable.mlqPip) {
        this.showPIPProduct = true;
      }
    }
    console.log('response', JSON.stringify(this.quote.accessRecResponse));
      if (this.quote.accessRecResponse && this.quote.accessRecResponse.nid) {
        console.log('nid', this.quote.accessRecResponse.nid);
        this.showNid = true;
      }
      console.log('showNid', this.showNid);
      if (this.isGenICBFlow){        
        this.GenICBFlow = true;
        console.log('ICB1', this.isGenICBFlow);
      }
      console.log('ICB2', this.isGenICBFlow);
        // ServiceType
        if (this.quote.accessRecResponse.litCapability === 'Off-Net' && this.quote.accessRecResponse.accessType != null && this.quote.accessRecResponse.serviceType != null && this.quote.productAttributes.productOffering === this.lable.mlqOfferSWUniEvc) {
          this.showServiceType = true;
        }
        if(this.quote.productAttributes.productOffering === this.lable.mlqOfferIDEPlus && this.quote.access && this.quote.access.carrierDiversity && this.quote.accessRecResponse.accessType && this.quote.accessRecResponse.accessType.includes('4') && this.quote.access.carrierDiversity.serviceType){
          this.showServiceType = true;
        }
    //Access
    if (this.quote.accessRecResponse.litCapability != null && this.quote.accessRecResponse.accessType != null) {


      if (this.quote.productAttributes.productOffering === this.lable.mlqOfferSWUniEvc) {
        this.showUniAccess = true;
      }
      else if (this.quote.productAttributes.productOffering === this.lable.mlqOfferIDE || this.quote.productAttributes.productOffering === this.lable.mlqOfferIDEPlus || this.quote.productAttributes.productFamily === this.lable.mlqPip) {
        this.showAccess = true;
      }
    }
    //Expected Carrier
    if (this.quote.productAttributes.productOffering != this.lable.mlqOfferIDEPlus) {
      if (this.quote.accessRecResponse.accessProviderName != null && this.quote.accessRecResponse.accessType != null) {
        let accessType = this.quote.accessRecResponse.accessType;
        if (accessType === 'Type3' || accessType === 'Type4' || accessType === 'Type5') {//Modified by Praveen | Ethernet International
          this.showExpectedCarrier = true;
            }
        }
    }
        if(this.quote.productAttributes.productFamily === this.lable.mlqSWElineTLS){
          this.showTLSProduct = true;
        }
        //Location Detail
        if((this.quote.location.addrValResponse.lineofbusiness === 'VZT' && this.quote.productAttributes.productFamily !== this.lable.mlqSWElineTLS) || (this.quote.location.addrValResponse.lineofbusiness == 'VZB' && this.quote.accessRecResponse.accessType == 'Type2' )){
          if(this.quote.accessRecResponse.locationDetail){
              this.locationDetailsVal = this.quote.accessRecResponse.locationDetail;
                this.showLocationDetail = true;
            }else if(this.quote.location.locationDetail){
              this.locationDetailsVal = this.quote.location.locationDetail;
              this.showLocationDetail = true;
            }
        }
        //IOF Miles 10G check
        if(this.quote.productAttributes.iofMileage && this.quote.productAttributes.iofMileage != '0' && (this.quote.productAttributes.portAndAccessSpeed ==='10 Gbps' || this.quote.productAttributes.portAndAccessSpeed ==='10 G')){
          this.isIOFSpeed = true;
        }
        // PortConfiguration
        if(this.quote.productAttributes.portConfiguration != null && (this.quote.productAttributes.productOffering === this.lable.mlqOfferIDE || this.quote.productAttributes.productOffering === this.lable.mlqOfferIDEPlus)){
                this.showPortConfig = true;
                //Nikhil added for DDoS
                if(this.quote.productAttributes.productOffering === this.lable.mlqOfferIDEPlus && this.quote.ddos == 'Y'){
                  this.isDDoS = true;
                }else{
                  this.isDDoS = false;
                }

                if(this.quote.productAttributes.portAndAccessSpeed && this.quote.productAttributes.portAndAccessSpeed != undefined){
                  this.speedDisplayText = 'Port: ' + this.quote.productAttributes.portAndAccessSpeed + ' ';
                  this.speedDisplayText = this.speedDisplayText + 'Access: ' + this.quote.productAttributes.portAndAccessSpeed + ' ';
      }
      if (this.quote.productAttributes.commitSpeed && this.quote.productAttributes.commitSpeed != undefined) {
        this.speedDisplayText = this.speedDisplayText + 'Commit: ' + this.quote.productAttributes.commitSpeed + ' ';
      }
                if(this.quote.productAttributes.interfaceSpeed && this.quote.productAttributes.interfaceSpeed != undefined){
                  this.speedDisplayText = this.speedDisplayText + 'Interface: ' + this.quote.productAttributes.interfaceSpeed + ' ';
                }
                else if(this.quote.productAttributes.portConfiguration === 'Burstable'){
                    if(this.quote.productAttributes.commitSpeed && this.quote.productAttributes.commitSpeed != undefined){
                      this.speedDisplayText = this.speedDisplayText + 'Commit: ' + this.quote.productAttributes.commitSpeed;
                    }
                }
        }
        // Targetprice
        if(((this.quote.prices.targetMRC != null  && this.quote.prices.targetMRC !== '' && this.quote.prices.targetMRC !== '0.00')  || (this.quote.prices.targetNRC !== null && this.quote.prices.targetNRC !== '' && this.quote.prices.targetNRC !== '0.00')) && !this.statusesToAvoidDisplay.includes(this.quote.status)){
              this.showTargetPrice = true;
        }
        if((this.quote.prices.targetMRC != null  && this.quote.prices.targetMRC !== '' && this.quote.prices.targetMRC !== '0.00')  || (this.quote.prices.targetNRC !== null && this.quote.prices.targetNRC !== '' && this.quote.prices.targetNRC !== '0.00')){
            this.displayCustomQuoteComments = true;
        }
        if(this.quote.location.locationDetail != '' && this.quote.location.locationDetail != null && this.quote.productAttributes.productFamily !== this.lable.mlqSWElineTLS && this.quote.accessRecResponse.accessType == 'Type2'){
          let zval = this.quote.location.locationDetail;
          const zValArray = zval.split(" ");
          this.zoneValueAccess = '-'+' '+zValArray[2]+' '+zValArray[3];
          this.zoneValue = '('+ this.quote.location.locationDetail+')';
        }
        //Start - Added by Pushpendra | Shop Internatioanl
        if(this.quote.access.carrierDiversity && JSON.stringify(this.quote.access.carrierDiversity) != '{}' && this.quote.access.carrierDiversity.accessProvider ){
          if(this.quote.access.carrierDiversity.accessProviderName){
            this.ProviderValue = this.quote.access.carrierDiversity.accessProviderName;
          }else{
            this.ProviderValue = this.quote.access.carrierDiversity.accessProvider;
          }
          this.showDiversity = true;
          if(!this.ProviderValue){//Nikhil added VBGP7212
            this.showDiversity = false;
          }
        } 
        //Start-Added by Suveatha | Shop International
        //if(this.quote.accessRecResponse.isRecommended == 'true' && this.quote.access.carrierDiversity == null){
        if(this.quote.accessRecResponse.accessType && (this.quote.access.carrierDiversity == null || JSON.stringify(this.quote.access.carrierDiversity) === '{}')){
          let accessType = this.quote.accessRecResponse.accessType;
          if (accessType === 'Type3' || accessType === 'Type4' || accessType === 'Type5') {
            this.isRecommended = true;
          }
        }
        //End-Added by Suveatha | Shop International
        if(this.quote.productAttributes.productOffering === this.lable.mlqOfferIDEPlus){
          this.showIDPlusProduct = true;
          if(this.verizonLegalEntity && this.verizonLegalEntity != '--Select One--' && this.verizonLegalEntity != ''){
            this.showVLEForIDPlus = true;
          }
        }
        //End - Added by Pushpendra | Shop Internatioanl
        //Added by Suveatha | Generic ICB Summary
        if(this.quote.tolocation.value){
          this.toLocation = true;
        }
    }

  get showCPProdOffering() {
    if (this.quote.productAttributes.productOffering === this.lable.mlqOfferWaveCP) {
      return true;
    }
    return false;
  }

  statusesToAvoidDisplay = ['Pricing Updated', 'Submitted', 'Completed', 'Expired'];
  displayCustomQuoteComments = false;

  openModal() {
    // to open modal set isModalOpen tarck value as true
    this.isModalOpen = true;

  }

  closeModal() {
    // to close modal set isModalOpen tarck value as false
    this.isModalOpen = false;
    const selectedEvent = new CustomEvent("summarymodelclose", {
      detail: this.isModalOpen
    });
    this.dispatchEvent(selectedEvent);
  }


  @wire(showHistoryList, { quoteId: "$quote.QuoteId" })
  showHistoryList({ error, data }) {
    if (error) {
      this.error = error;
      console.log('Error inside showHistoryList::', error);
    } else if (data) {
      this.quoteHistDetails = JSON.parse(data);
      this.checkQuoteHistorySize();
    }
  }

  checkQuoteHistorySize() {
    if (this.quoteHistDetails.length > 10) {
      this.quoteHistDetailsSliced = this.quoteHistDetails.slice(0, 3);
    } else {
      this.quoteHistDetailsSliced = this.quoteHistDetails;
    }
  }

  //Start - Added by Sakthi Brindha | MLQ PL
  get plAccesstype() {
    if (this.quote.productAttributes.productOffering == 'Metro Private Line' || this.quote.productAttributes.productOffering == 'US Private Line') {
      if (this.quote.location.addrValResponse.lineofbusiness == 'VZT') {
        this.fromacc = 'Offnet';
        this.msg = 'Verizon';
        return true;
      } else {
        if (this.quote.location.addrValResponse.lineofbusiness == 'VZB') {
          if (this.quote.location.addrValResponse.vzbLit == 'false' || this.quote.location.addrValResponse.vzbLit == undefined) {
            if (this.quote.location.addrValResponse.litCapability == 'On-Net' && (this.quote.location.addrValResponse.colocationRestricted == 'No' || this.quote.location.collocationOverride == true)) {
              this.fromacc = 'Onnet';
              this.msg = 'Verizon';
              return true;
            } else {
              this.fromacc = 'Offnet';
              this.msg = this.quote.accessRecResponse.provider;
              return true;
            }
          }
        } else {
          if (this.quote.location.addrValResponse.vzbLit == 'true') {
            this.fromacc = 'Verizon On Net';
            this.msg = 'Verizon';
            return true;
          }
        }
      }
    } else {
      return false;
    }
  }


  get plToAccesstype() {
    if (this.quote.productAttributes.productOffering == 'Metro Private Line' || this.quote.productAttributes.productOffering == 'US Private Line') {
      if (this.quote.tolocation.addrValResponse.lineofbusiness == 'VZT') {
        this.toacc = 'Offnet';
        this.tomsg = 'Verizon';
        return true;
      } else {
        if (this.quote.tolocation.addrValResponse.lineofbusiness == 'VZB') {
          if (this.quote.tolocation.addrValResponse.vzbLit == 'false' || this.quote.tolocation.addrValResponse.vzbLit == undefined) {
            if (this.quote.tolocation.addrValResponse.litCapability == 'On-Net' && (this.quote.tolocation.addrValResponse.colocationRestricted == 'No' || this.quote.tolocation.collocationOverride == true)) {
              this.toacc = 'Onnet';
              this.tomsg = 'Verizon';
              return true;
            } else {
              this.toacc = 'Offnet';
              this.tomsg = this.quote.accessRecResponse.provider;
              return true;
            }
          }
        } else {
          if (this.quote.tolocation.addrValResponse.vzbLit == 'true') {
            this.toacc = 'Verizon On Net';
            this.tomsg = 'Verizon';
            return true;
          }
        }
      }
    } else {
      return false;
    }
  }

  get isUSPL() {
    if (this.quote.productAttributes.productOffering == 'US Private Line') {
      return true;
    } else {
      return false;
    }
  }

  get isTSP() {
    if (this.quote.tspVal) {
      return true;
    } else {
      return false;
    }
  }
  get isTSPShow() {
    if (this.quote.productAttributes && this.quote.productAttributes.TSPOption != undefined && this.quote.locationType != 'International') {
      return true;
    } else {
      return false;
    }
  }
  //End - Added by Sakthi Brindha | MLQ PL
  get contractVal() {
    if(this.quote) {
      return this.quote.contract == 'EX22270404'?'STANDARD':this.quote.contract;
    }
    else{
      return '';
    }
  }
}
