/******************************************************************************************
* Component:      VPS_OrderWorklist_LightningDatatable
* @description    This class is used by the full worklist components and is in charge of 
*                 searching for the user's orders and displaying them with the desired 
*                 filters and input
*********************************************Change Log*********************************************************
UserStory			Date			Developer					Description							
VBGSD-153		  27/05/2021	 Sandipan Patra		Fetch values for orderType picklist.
****************************************************************************************************************/
public without sharing class VPS_OrderWorklist_LightningDatatable {
    
    @AuraEnabled public Map<Id,Quote> quoteMap;
    @AuraEnabled public Map<Id,Order> orderMap;
    
    @AuraEnabled
    public static QuoteOrderWrap1 getrecords1(String searchKey,String orderStatus, Integer rowLimit, Integer rowOffset) {
        
       
        VPS_OrderWorklist_LightningDatatable obj = new VPS_OrderWorklist_LightningDatatable();
        
        
        List<Id> accountHIDs = getAccountHierarchy();
        
        date orderSearch;
        Boolean IsDate = false;
        try {
            
            orderSearch = date.parse(searchKey);
            
            IsDate = true;
        } catch(exception e){
            System.debug('Search key was not a date. This is not an error');
        }
        //Start - Modified/Added by Ashish || New Role changes || 4-2-2022
        user userRec    =   [SELECT Id,VPS_IsDeliveryRole__c,contactId,VPS_IsOrderingRole__c FROM User WHERE Id = : UserInfo.getUserId() limit 1];// Added by Ashish New User role changes
       
        Contact con = [SELECT id,Name,AccountId,isSuperUser__c from Contact where id =:userRec.ContactId limit 1];
        //End - Modified/Added by Ashish || New Role changes || 4-2-2022
               
        QuoteOrderWrap1 wrapresponse = new QuoteOrderWrap1();
        List<Quote> quoteLst = new List<Quote>();
        Set<Id> quoteId = new Set<Id>();
        
        
if(userRec.VPS_IsOrderingRole__c ==true){
            
            List<Order> orderlist = new List<Order>();
            if(IsDate == true) {
                orderlist = [SELECT Quote.Description,Id,Omniscript_Instance_Id__c, VPS_OrderType__c,VPS_AssetId__c,Vps_Related_Order__c, QuoteId,VPS_ProductOffering_WKL__c,VPS_Product_Type__c,VPS_OrderFlag__c,VPS_Date_Submitted__c 
                             ,VPS_Due_Date__c ,OrderNumber,Name,VPS_Project_Id__c,status,VPS_Milestone_Status__c,VPS_milestoneVsCompletionDate__c,ServicePlatform2__c,ProductName__c
                             FROM Order WHERE
                             (VPS_Date_Submitted__c = :orderSearch or VPS_Due_Date__c = :orderSearch)
                             AND Name != 'Toll Free Name'
                             AND (CreatedbyId= :UserInfo.getUserID() OR  ownerId= :UserInfo.getUserID())
                             order by VPS_OrderFlag__c desc,createddate desc LIMIT :rowLimit OFFSET :rowOffset ];
                 
                wrapresponse.totalRecords = [SELECT COUNT() FROM Order WHERE
                                             (VPS_Date_Submitted__c = :orderSearch or VPS_Due_Date__c = :orderSearch)  
                                             AND (CreatedbyId= :UserInfo.getUserID() OR  ownerId= :UserInfo.getUserID()) ]; 
                
            } else if((searchKey!=null && searchKey!='') && ( String.isEmpty(orderStatus) )) {
                if(searchKey == 'Activation'){
		    //Added condition to filter records based on createdById or ownerId
                    //List<List<sObject>> searchList = [FIND 'Activation' IN ALL FIELDS RETURNING Order(Id)];
                    List<List<sObject>> searchList = [FIND 'Activation' IN ALL FIELDS RETURNING Order(Id WHERE CreatedbyId= :UserInfo.getUserID() OR  ownerId= :UserInfo.getUserID())];
                    
                    Order[] searchOrders = (Order[])searchList[0];
                    Set<Id> resultIds = new Set<Id>();
                    for(Integer i = 0;i<searchOrders.size();i++)
                        resultIds.add(searchOrders[i].Id);
                    
                    orderlist = [SELECT Quote.Description,Id, Omniscript_Instance_Id__c, VPS_OrderType__c, VPS_AssetId__c, VPS_Related_Order__c, QuoteId, VPS_ProductOffering_WKL__c, VPS_Product_Type__c, 
                                 VPS_OrderFlag__c, VPS_Date_Submitted__c, VPS_Due_Date__c, OrderNumber, Name, VPS_Project_Id__c, Status, VPS_Milestone_Status__c, 
                                 VPS_milestoneVsCompletionDate__c,ServicePlatform2__c, ProductName__c
                                 FROM Order WHERE Id in :resultIds AND Name != 'Toll Free Name'];
                    
                    wrapresponse.totalRecords = resultIds.size();
                    
                }else{
                     String keyForSearch = '%' + searchKey + '%';
                    keyForSearch = String.escapeSingleQuotes(keyForSearch);
                    
                     //Start - Added by Ashish || New Role changes || 4-2-2022
                    string conditionalOwner;
                    if(con.isSuperUser__c){
                        conditionalOwner = 'AccountID IN: accountHIDs  AND ';
                    }else{
                        conditionalOwner = '(OwnerId= \'' + UserInfo.getUserID() +'\' or createdbyid= \'' +UserInfo.getUserID() + '\'  or AccountID IN: accountHIDs )  AND ';
                        }
					//End - Added by Ashish || New Role changes || 4-2-2022
					
                    String query = 'SELECT Quote.Description,Id, VPS_OrderType__c, VPS_AssetId__c, VPS_Related_Order__c, Omniscript_Instance_Id__c, QuoteId, ' +
                        		' VPS_ProductOffering_WKL__c, VPS_Product_Type__c, VPS_OrderFlag__c, VPS_Date_Submitted__c, VPS_Due_Date__c, OrderNumber, ' +
                        		' Name, VPS_Project_Id__c, Status, VPS_Milestone_Status__c, VPS_milestoneVsCompletionDate__c,ServicePlatform2__c, ProductName__c ' +
                        ' FROM Order WHERE '+ conditionalOwner + //Modified by Ashish || Added conditionalOwner || 4-2-2022
                         '(Name != \'Toll Free Name\') AND '+
                        '(Name like \'' + keyForSearch + '\' OR Status like \'' +  keyForSearch + '\' OR VPS_Project_Id__c like \'' + keyForSearch + '\'' +
                        						' OR ' + getProductOfferingSearchWhereClause(keyForSearch) + ' OR VPS_Product_Type__c like \'' + keyForSearch + '\'' +
                        						' OR VPS_Milestone_Status__c like \'' + keyForSearch + '\')' +
                                 ' ORDER BY VPS_OrderFlag__c DESC, createddate DESC LIMIT ' + rowLimit + ' OFFSET ' + rowOffset;
                    
                    
                    orderlist = Database.query(query);
                    
                    query = 'SELECT COUNT() FROM Order WHERE '+ conditionalOwner + //Modified by Ashish || Added conditionalOwner || 4-2-2022
                        	'(Name like \'' + keyForSearch + '\' OR Status like \'' + keyForSearch + '\'' + 
                        				' OR VPS_Project_Id__c like \'' + keyForSearch + '\' OR ' + getProductOfferingSearchWhereClause(keyForSearch) +
                                        ' OR VPS_Product_Type__c like \'' + keyForSearch +'\' OR VPS_Milestone_Status__c like \'' + keyForSearch + '\') ';

                	wrapresponse.totalRecords = Database.countQuery(query); 
                    
                    /*String keyForSearch = '%' + searchKey + '%';
                   
                    orderlist = [SELECT Id,Omniscript_Instance_Id__c, VPS_OrderType__c,VPS_AssetId__c,Vps_Related_Order__c, QuoteId,VPS_ProductOffering_WKL__c,VPS_Product_Type__c,VPS_OrderFlag__c,VPS_Date_Submitted__c 
                                 ,VPS_Due_Date__c ,OrderNumber,Name,VPS_Project_Id__c,status,VPS_Milestone_Status__c,VPS_milestoneVsCompletionDate__c,ServicePlatform2__c,ProductName__c
                                 FROM Order 
                                 WHERE
                                 (Name like:keyForSearch or 
                                  status like:keyForSearch or 
                                  VPS_Project_Id__c like:keyForSearch OR 
                                  VPS_ProductOffering_WKL__c like:keyForSearch OR 
                                  VPS_Product_Type__c like:keyForSearch OR
                                  VPS_Milestone_Status__c like:keyForSearch) 
                                 
                                 //(CreatedbyId= '0051h000001jY68AAE' OR  ownerId= '0051h000001jY68AAE')
                                // (CreatedbyId= :UserInfo.getUserID() OR  ownerId= :UserInfo.getUserID()) AND AccountId IN :AccountIds  
                                 order by VPS_OrderFlag__c desc,createddate desc LIMIT :rowLimit OFFSET :rowOffset ];
                   
                    wrapresponse.totalRecords = [SELECT COUNT() FROM Order WHERE
                                                 (Name like:keyForSearch or status like:keyForSearch OR VPS_Project_Id__c like:keyForSearch or 
                                                  VPS_ProductOffering_WKL__c like:keyForSearch or VPS_Product_Type__c like:keyForSearch OR
                                                  VPS_Milestone_Status__c like:keyForSearch) /*AND 
(status IN ('New','Open','Submitted','Completed','Change Requested') 
OR VPS_Milestone_Status__c IN ('','Acceptance','Build', 'Confirmation','Completion', 'Network Evaluation','Provisioning'))*/
                                              /*   AND (CreatedbyId= :UserInfo.getUserID() OR  ownerId= :UserInfo.getUserID())
                                                ];*/
                    
                }
            } else if((searchKey!=null && searchKey!='') && ( String.isNotEmpty(orderStatus) )) {
        			
                	
                	String keyForSearch = '%' + searchKey + '%';
                    keyForSearch = String.escapeSingleQuotes(keyForSearch);
					String keyForSearchOrderStatus = '%' + orderStatus + '%';
                    keyForSearchOrderStatus = String.escapeSingleQuotes(keyForSearchOrderStatus);
                    String query = 'SELECT Quote.Description,Id, VPS_OrderType__c, VPS_AssetId__c, VPS_Related_Order__c, Omniscript_Instance_Id__c, QuoteId, ' +
                        		' VPS_ProductOffering_WKL__c, VPS_Product_Type__c, VPS_OrderFlag__c, VPS_Date_Submitted__c, VPS_Due_Date__c, OrderNumber, ' +
                        		' Name, VPS_Project_Id__c, Status, VPS_Milestone_Status__c, VPS_milestoneVsCompletionDate__c,ServicePlatform2__c, ProductName__c ' +
                        ' FROM Order WHERE (OwnerId= \'' + UserInfo.getUserID() + '\' or createdbyid= \'' + UserInfo.getUserID() + '\')  AND ' +
                        '(Name != \'Toll Free Name\') AND '+
                        '( Status like \'' +  keyForSearchOrderStatus + '\'' +
                        ' AND VPS_Product_Type__c like \'' + keyForSearch + '\')' +
						' ORDER BY VPS_OrderFlag__c DESC, createddate DESC LIMIT ' + rowLimit + ' OFFSET ' + rowOffset;
                    
                    
                    
                	orderlist = Database.query(query);
                    
                    query = 'SELECT COUNT() FROM Order WHERE (OwnerId= \'' + UserInfo.getUserID() + '\' or createdbyid= \'' + UserInfo.getUserID() + '\'  )  AND ' +
                        	'Status like \'' + keyForSearchOrderStatus + '\'' + 
                        	' AND VPS_Product_Type__c like \'' + keyForSearch + '\'' ;
                	wrapresponse.totalRecords = Database.countQuery(query); 
              
            } else if(String.isEmpty(searchKey) && String.isNotEmpty(orderStatus) ) {
        			
                	
					String keyForSearchOrderStatus = '%' + orderStatus + '%';
                    keyForSearchOrderStatus = String.escapeSingleQuotes(keyForSearchOrderStatus);
                    String query = 'SELECT Quote.Description,Id, VPS_OrderType__c, VPS_AssetId__c, VPS_Related_Order__c, Omniscript_Instance_Id__c, QuoteId, ' +
                        		' VPS_ProductOffering_WKL__c, VPS_Product_Type__c, VPS_OrderFlag__c, VPS_Date_Submitted__c, VPS_Due_Date__c, OrderNumber, ' +
                        		' Name, VPS_Project_Id__c, Status, VPS_Milestone_Status__c, VPS_milestoneVsCompletionDate__c,ServicePlatform2__c, ProductName__c ' +
                        ' FROM Order WHERE (OwnerId= \'' + UserInfo.getUserID() + '\' or createdbyid= \'' + UserInfo.getUserID() + '\')  AND ' +
                        '(Name != \'Toll Free Name\') AND' +
                        ' Status like \'' +  keyForSearchOrderStatus + '\'' +
						' ORDER BY VPS_OrderFlag__c DESC, createddate DESC LIMIT ' + rowLimit + ' OFFSET ' + rowOffset;
                    
                    
                    
                	orderlist = Database.query(query);
                    
                    query = 'SELECT COUNT() FROM Order WHERE (OwnerId= \'' + UserInfo.getUserID() + '\' or createdbyid= \'' + UserInfo.getUserID() + '\'  )  AND ' +
                        	'Status like \'' + keyForSearchOrderStatus + '\'' ;
                	wrapresponse.totalRecords = Database.countQuery(query); 
              }
			    else{
                   //Start - Modified/Added by Ashish || New Role changes || 2-2-2022
                //String accID =  String.escapeSingleQuotes(con.AccountId);
                
                  if(con.isSuperUser__c) {
                      List<Id> accHierIds = getAccountHierarchy();
                      
                      orderlist = [SELECT 
                                       Quote.Description,Id, VPS_OrderType__c,VPS_AssetId__c,Vps_Related_Order__c,Omniscript_Instance_Id__c,
                                       QuoteId,VPS_ProductOffering_WKL__c,VPS_OrderFlag__c,VPS_Date_Submitted__c ,VPS_Due_Date__c ,
                                       OrderNumber,Name,VPS_Project_Id__c,VPS_Product_Type__c,status,VPS_Milestone_Status__c,
                                       VPS_milestoneVsCompletionDate__c,ServicePlatform2__c,ProductName__c,AccountId
                                   FROM Order 
                                   WHERE  Name != 'Toll Free Name' AND
                                   AccountId IN :accHierIds AND 
                                   (CreatedbyId= :UserInfo.getUserID() OR  ownerId= :UserInfo.getUserID()) 
                                   ORDER BY VPS_OrderFlag__c DESC,createddate DESC 
                                   LIMIT :rowLimit 
                                   OFFSET :rowOffset
                                  ];
                      
                      wrapresponse.totalRecords = [SELECT
                                                   	COUNT() 
                                                   FROM Order 
                                                   WHERE (CreatedbyId= :UserInfo.getUserID() OR  ownerId= :UserInfo.getUserID())
                                                   AND AccountId IN :accHierIds
                                                  ];
                  }
                  else{//End - Modified/Added by Ashish || New Role changes ||2-2-2022
                      orderlist = [SELECT Quote.Description,Id, VPS_OrderType__c,VPS_AssetId__c,Vps_Related_Order__c,Omniscript_Instance_Id__c,QuoteId,VPS_ProductOffering_WKL__c,VPS_OrderFlag__c,VPS_Date_Submitted__c 
                                   ,VPS_Due_Date__c ,OrderNumber,Name,VPS_Project_Id__c,VPS_Product_Type__c,status,VPS_Milestone_Status__c,VPS_milestoneVsCompletionDate__c,ServicePlatform2__c,ProductName__c,AccountId
                                   FROM Order 
                                   WHERE  Name != 'Toll Free Name' AND
                                   (CreatedbyId= :UserInfo.getUserID() OR  ownerId= :UserInfo.getUserID()) // AND status !='New')//commented status !='New' for 43455 bug
                                   order by VPS_OrderFlag__c desc,createddate desc LIMIT :rowLimit OFFSET :rowOffset];
                      
                      wrapresponse.totalRecords = [SELECT COUNT() FROM Order where (CreatedbyId= :UserInfo.getUserID() OR  ownerId= :UserInfo.getUserID())];
                  }
                
                /*
                wrapresponse.totalRecords = [SELECT COUNT() FROM Order where (status IN ('New','Open','Submitted','Completed','Change Requested') 
                                                                              OR VPS_Milestone_Status__c IN ('','Acceptance','Build', 'Confirmation','Completion', 'Network Evaluation','Provisioning'))
                                             AND (CreatedbyId= :UserInfo.getUserID() OR  ownerId= :UserInfo.getUserID())
                                            ];
                */
                
                
            }
              
            
            wrapresponse.Orderdatalst = getOrderWrapList(orderlist,userRec.VPS_IsOrderingRole__c) ;
            
        }
        //}
        
        return wrapresponse;   
    } 
    //Added fro retrofitment
    private static String getProductOfferingSearchWhereClause(String searchKey) {
        String poWhereClause = ' ( VPS_ProductOffering_WKL__c like \'' + searchKey + '\'';
        searchKey = searchKey.replace('%', '');
        String lowerSearchKey = searchKey.toLowerCase();
        if('uni standalone'.contains(lowerSearchKey)) {
            poWhereClause += ' OR VPS_ProductOffering_WKL__c = \'ERS Premier UNI\' ';
        }
       // if('uni/evc combo'.contains(lowerSearchKey)) {
       if(('uni/evc combo'.contains(lowerSearchKey))) {  // Added or condition for 2969_ITR_revert
           
            poWhereClause += ' OR VPS_ProductOffering_WKL__c = \'UNI EVC\' ';
        }
        if('evc standalone'.contains(lowerSearchKey)) {
            poWhereClause += ' OR VPS_ProductOffering_WKL__c = \'ERS PREMIER EVC\' ';
        } 
        poWhereClause += ' )';
        
        return poWhereClause;
    }  
    public class QuoteOrderWrap1 {
        //Total records added by Sandra for lazy loading
        @AuraEnabled
        public Integer totalRecords = 0;
        @AuraEnabled
        public List<Orderwrap> Orderdatalst;
        public QuoteOrderWrap1(){
            Orderdatalst = new List<Orderwrap>();
        }
    }
    public class OrderObjectData { 
        @AuraEnabled
        public String Name;  
        @AuraEnabled
        public String projectId;
        @AuraEnabled
        public String product;
        @AuraEnabled
        public String productCode;			
        @AuraEnabled
        public string productOffering;
        @AuraEnabled
        // public Date dateSubmitted;
        public String dateSubmitted;
        @AuraEnabled
        //public Date dueDate;
        public String dueDate;
        @AuraEnabled
        public string Status;
        @AuraEnabled
        public string milestoneStatus;
        @AuraEnabled
        public Boolean isActivation = false;//[SWARS]
        @AuraEnabled
        public string link;
        @AuraEnabled
        public String orderId;
        @AuraEnabled
        public String OSInstId;
        @AuraEnabled
        public String OfferType;
        @AuraEnabled
        public Boolean userHasDeliveryRole; 
        @AuraEnabled
        public Boolean userHasOrderingRole;
        @AuraEnabled
        public Boolean flag;  
        // Added for Revamp Project - Surendra
        @AuraEnabled
        public string OrderType;
        @AuraEnabled
        public string AssetId;
        @AuraEnabled
        public string RelatedOrderId;  // End 
        @AuraEnabled 
        public string ServicePlaform;    //Added by Dinesh
        @AuraEnabled
        public string ProductType;//Added By Mahesh   
		@AuraEnabled 
        public string quoteDescription; //vrd changes 
    }
    
    
    public class Orderwrap{
        
        
        @AuraEnabled
        public OrderObjectData Orderdata;
        
        @AuraEnabled
        public String Productname;
	
        @AuraEnabled
        public String Address;
        
        public Orderwrap(){
            //      Orderdata = new Order();
        }
        
    }
    
    
    
    @AuraEnabled 
    public static List<Orderwrap> getOrderWrapList(List<Order> orderlist, Boolean userHasOrderingRole){
        list<string> quoteIds = new list<string>();
        list<string> quoteInstIds = new list<string>(); 
        map<string, quote> quoteIdVsQuoteObj = new map<string, quote>();
        //map<string, quote> orderIdVsQuoteObj = new map<string, quote>();
        map<string, Attachment> quoteInstanceIdVsAttachmentObj = new map<string, Attachment>();
        /*map<string, order> orderIdVsOrderObj = new map<string, order>();            
for(order eachOrder : orderlist){
quoteIds.add(eachOrder.QuoteId);
orderIdVsOrderObj.put(eachOrder.id,eachOrder);          
}*/
        
        
        string filename = 'OmniScriptDataJSON.json';
        
        List<Orderwrap> orderwraplist = new List<Orderwrap>();
        
        Map<string,string> urlParamsMap = new Map<string,string>();
        //  Surendra**  Added for Revemp Project URL Creation for Omniscript/
	//3057_ITR to avoid duplicate Extension record
        List<VPS_Quote_Order_Extension__c> extObjLst = [Select id, name,VPS_Quote__c,VPS_Order__c,trackKey__c,layout__c,OmnicancelAction__c, Omniframeembeded__c,
                                                        isDTP__c ,sfdciFrameOrigin__c,sfdciFrameHost__c, Productid__c,Product__c,Product__r.ProductCode,(Select id, Field_Name__c,Field_Value__c from VPS_Resume_Extentions__r where Field_Name__c ='OfferType_PTP') from VPS_Quote_Order_Extension__c 
                                                        where VPS_Order__c =:orderlist and VPS_Quote__c !=null];  /// [SKB]
        map<string, VPS_Quote_Order_Extension__c> orderIdToExtnObjMap = new map<string, VPS_Quote_Order_Extension__c>();
        for(VPS_Quote_Order_Extension__c eachExtnObj: extObjLst){
            orderIdToExtnObjMap.put(eachExtnObj.VPS_Order__c, eachExtnObj);
        }
        
        
        for(Order orderdata : orderlist) {
            Orderwrap owrap = new Orderwrap();
            VPS_OrderWorklist_LightningDatatable.orderObjectData orderObjectData = new VPS_OrderWorklist_LightningDatatable.orderObjectData();
            orderObjectData.Name = orderdata.name;  
            orderObjectData.flag = orderdata.VPS_OrderFlag__c;  
            orderObjectData.projectId = orderdata.VPS_Project_Id__c;  
            orderObjectData.product = orderdata.VPS_Product_Type__c;
            orderObjectData.quoteDescription = orderdata.Quote.Description;//vrd changes
			
			orderObjectData.productCode = (orderIdToExtnObjMap.get(orderdata.id) != null && orderIdToExtnObjMap.get(orderdata.id).Product__c != null)? orderIdToExtnObjMap.get(orderdata.id).Product__r.ProductCode : '';
           
            if(orderObjectData.product == 'SIP Gateway'){
                orderObjectData.productCode = 'VOICE_SIP_OB';
            }else if(orderObjectData.product == 'GIPC'){
                orderObjectData.productCode = 'VOICE_GIPC_DD';
            }
			
            if(orderdata.VPS_ProductOffering_WKL__c == 'PIP Port & Access'){
                orderObjectData.productCode = 'PIP_OFR_UNI';
            }else if(orderdata.VPS_ProductOffering_WKL__c == 'PIP NNI Port & Access'){
                orderObjectData.productCode = 'PIP_OFR_NNI';
            }
			
            orderObjectData.productOffering = orderdata.VPS_ProductOffering_WKL__c;
            if(orderdata.VPS_Date_Submitted__c != null ){
                orderObjectData.dateSubmitted = String.valueOf(orderdata.VPS_Date_Submitted__c);
            }else{
                orderObjectData.dateSubmitted = '';
            }
            if(orderdata.VPS_Due_Date__c != null ){
                orderObjectData.dueDate = String.valueOf(orderdata.VPS_Due_Date__c);
            }else{
                orderObjectData.dueDate = '';
            }
            
            
            
            //orderObjectData.status = orderdata.status;
            orderObjectData.Status = orderdata.status;
            
            orderObjectData.milestoneStatus = orderdata.VPS_Milestone_Status__c;
            //[Start][SWARS]
            if(orderdata.VPS_milestoneVsCompletionDate__c != null && (orderdata.VPS_milestoneVsCompletionDate__c).contains('Activation'))
                orderObjectData.isActivation = true;
            else
                orderObjectData.isActivation = false;
            //[End][SWARS]
            //****** Surendra**  Added for Revemp Project URL Creation for Omniscript/
            Map<string,string> urlParamsMap1 = new Map<string,string>();
            String layout = orderIdToExtnObjMap.get(orderdata.id) != null ? orderIdToExtnObjMap.get(orderdata.id).layout__c : '';
            
            String trackKey = orderIdToExtnObjMap.get(orderdata.id) != null ? orderIdToExtnObjMap.get(orderdata.id).trackKey__c : '';
            String omniCancelAction = orderIdToExtnObjMap.get(orderdata.id) != null ? orderIdToExtnObjMap.get(orderdata.id).OmnicancelAction__c : '';
            String omniIframeEmbedded = orderIdToExtnObjMap.get(orderdata.id) != null ? orderIdToExtnObjMap.get(orderdata.id).Omniframeembeded__c : '';
            if(omniIframeEmbedded == 'Y' || omniIframeEmbedded != 'true')  // Added by Mahesh
            {
                omniIframeEmbedded = 'true';
            }
            String isdtp = orderIdToExtnObjMap.get(orderdata.id) != null ? orderIdToExtnObjMap.get(orderdata.id).isDTP__c : '';
            String sfdcIFrameOrigin = orderIdToExtnObjMap.get(orderdata.id) != null ? orderIdToExtnObjMap.get(orderdata.id).sfdciFrameOrigin__c : '';
            String sfdcIFrameHost = orderIdToExtnObjMap.get(orderdata.id) != null ? orderIdToExtnObjMap.get(orderdata.id).sfdciFrameHost__c : '';          
            urlParamsMap1.put('layout',layout );
            urlParamsMap1.put('trackKey',trackKey );
            urlParamsMap1.put('omniCancelAction',omniCancelAction );
            urlParamsMap1.put('omniIframeEmbedded',omniIframeEmbedded );
            urlParamsMap1.put('isdtp',isdtp);
            urlParamsMap1.put('sfdcIFrameOrigin', sfdcIFrameOrigin);
            urlParamsMap1.put('sfdcIFrameHost', sfdcIFrameHost);              
            urlParamsMap1.put('resumePage','false');
            //return JSON.serialize(urlParamsMap);
            
            //****Surendra*//****** 
            orderObjectData.OrderType = orderdata.VPS_OrderType__c;
            orderObjectData.AssetId = orderdata.VPS_AssetId__c;
            orderObjectData.RelatedOrderId = orderdata.Vps_Related_Order__c;  
            orderObjectData.ProductType=orderdata.VPS_Product_Type__c; //Added By Mahesh          
            
            orderObjectData.link = JSON.serialize(urlParamsMap1);
            orderObjectData.ServicePlaform=orderdata.ServicePlatform2__c;
            
            orderObjectData.orderId = orderdata.id;
            //orderObjectData.osInstId = orderdata.Omniscript_Instance_Id__c;
            orderObjectData.OSInstId = orderdata.Omniscript_Instance_Id__c;
            //orderObjectData.userHasDeliveryRole = userHasDeliveryRole;
            orderObjectData.userHasOrderingRole = userHasOrderingRole;
            //orderObjectData.link = linkOrders(orderdata.id);         
            
            //Faiz CHnages
            if(orderIdToExtnObjMap.get(orderdata.id) != null ){
                VPS_Quote_Order_Extension__c vqt = orderIdToExtnObjMap.get(orderdata.id);
                if(vqt.VPS_Resume_Extentions__r != null && vqt.VPS_Resume_Extentions__r.size() > 0){
                    //orderObjectData.OfferType = vqt.VPS_Resume_Extentions__r[0].Field_Value__c;
                    orderObjectData.OfferType = vqt.VPS_Resume_Extentions__r[0].Field_Value__c;
                }
            }
            
                  
            owrap.orderData = orderObjectData;
            orderwraplist.add(owrap);
        }
        //QuoteOrderWrap1 wrapresponse = new QuoteOrderWrap1();
        // wrapresponse.orderdatalst = orderwraplist;
        
        return orderwraplist;
    }
    
    
    @AuraEnabled
    public static QuoteOrderWrap1 updateRecords(String Company, String Owner, String Product, String OrderType, Integer rowLimit, Integer rowOffset){
        User userRec = [SELECT Id,VPS_IsDeliveryRole__c,VPS_IsOrderingRole__c FROM User WHERE Id = : UserInfo.getUserId()];
        List<Order> orderlist = new List<Order>();
        Company = String.escapeSingleQuotes(Company); 
        Owner = String.escapeSingleQuotes(Owner);
        Product = String.escapeSingleQuotes(Product);
        OrderType = String.escapeSingleQuotes(OrderType);
        QuoteOrderWrap1 wrapresponse = new QuoteOrderWrap1();
        List<Id> AccountIds = getAccountHierarchy();
        
		String tempValue = Product;//vrd changes
        //Define the initial search query, which takes every field from the Order object.
        String queryString;
        if(Product == 'Inbound Voice Services'){
        queryString='SELECT Id,Quote.Description, Omniscript_Instance_Id__c, VPS_OrderType__c,VPS_AssetId__c,Vps_Related_Order__c, QuoteId,VPS_ProductOffering_WKL__c,VPS_Product_Type__c,VPS_OrderFlag__c,ProductName__c,ServicePlatform2__c,'
                    + 'VPS_Date_Submitted__c,VPS_Due_Date__c ,OrderNumber,Name,VPS_Project_Id__c,status,VPS_Milestone_Status__c,VPS_milestoneVsCompletionDate__c FROM Order WHERE ' 
                    + '(Name != \'Toll Free Name\') AND'
            		+ '(status IN (\'Open\',\'Submitted\',\'Completed\',\'Change Requested\',\'In Progress\') OR VPS_Milestone_Status__c IN (\'Acceptance\',\'Build\', \'FOC Summary\',\'Completion\', \'Network Evaluation\',\'Provisioning\') ) ';
                
        }
        else{
        queryString= 'SELECT Quote.Description,Id,Omniscript_Instance_Id__c, VPS_OrderType__c,VPS_AssetId__c,Vps_Related_Order__c, QuoteId,VPS_ProductOffering_WKL__c,VPS_Product_Type__c,VPS_OrderFlag__c,ProductName__c,ServicePlatform2__c,'
                    + 'VPS_Date_Submitted__c,VPS_Due_Date__c ,OrderNumber,Name,VPS_Project_Id__c,status,VPS_Milestone_Status__c,VPS_milestoneVsCompletionDate__c FROM Order WHERE ' 
                    + '(status IN (\'New\',\'Open\',\'Submitted\',\'Completed\',\'Change Requested\',\'In Progress\') OR VPS_Milestone_Status__c IN (\'Acceptance\',\'Build\', \'FOC Summary\',\'Completion\', \'Network Evaluation\',\'Provisioning\') ) ';	
                
        }
          //  + ' AND AccountId IN :AccountIds'
        
        //countRecords is for lazy loading to set totalRecords
        String countRecords = 'SELECT COUNT() FROM Order WHERE  ' 
            + '(status IN (\'New\',\'Open\',\'Submitted\',\'Completed\',\'Change Requested\',\'In Progress\') ' 
            +' OR VPS_Milestone_Status__c IN (\'Acceptance\',\'Build\', \'FOC Summary\',\'Completion\', \'Network Evaluation\',\'Provisioning\') )';
        //	+ ' AND AccountId IN :AccountIds'
        
        //Check to see which categories are being searched by, 
        //values will be 'None' by default or if the user resets by a category.
        if(Company == 'None' && Owner == 'None' && Product == 'None' && OrderType == 'None')
        {
            queryString += ' AND AccountId IN :AccountIds';
            countRecords += ' AND AccountId IN :AccountIds';
		}
		else{
        if(Company != 'None')
        {
            queryString += ' AND AccountId = ' + '\''+ Company + '\'';
            countRecords += ' AND AccountId = ' + '\''+ Company + '\'';
            /*queryString += ' OR AccountId = ' + '\''+ Company + '\'';
            countRecords += ' OR AccountId = ' + '\''+ Company + '\'';*/
        }
        if(Owner != 'None') 
        {
            queryString += ' AND (CreatedById = ' + '\'' + Owner + '\' OR OwnerId =  ' + '\'' + Owner + '\')'  ;
            countRecords += ' AND (CreatedById = ' + '\'' + Owner + '\' OR OwnerId =  ' + '\'' + Owner + '\')'  ;
            
           /* queryString += ' OR (CreatedById = ' + '\'' + Owner + '\' OR OwnerId =  ' + '\'' + Owner + '\')'  ;
            countRecords += ' OR (CreatedById = ' + '\'' + Owner + '\' OR OwnerId =  ' + '\'' + Owner + '\')'  ;*/
			
        }
        if(Product != 'None')
        {
			if(Product == 'Internet Dedicated +'){
                Product = 'Internet Dedicated Ethernet';
			}
            if(Company == 'None' || Owner == 'None'){
                 queryString += ' AND AccountId IN :AccountIds AND VPS_Product_Type__c = ' + '\'' + Product + '\'';
            	 countRecords += ' AND AccountId IN :AccountIds AND VPS_Product_Type__c = ' + '\'' + Product + '\'';
            }else{
                 queryString += ' AND VPS_Product_Type__c = ' + '\'' + Product + '\'';
            	 countRecords += ' AND VPS_Product_Type__c = ' + '\'' + Product + '\'';
            }
            String servType = 'VzB VRD';
            if(tempValue=='Internet Dedicated Ethernet'){
                queryString += ' AND ServicePlatform2__c != ' + '\'' + String.escapeSingleQuotes(servType) + '\'';
            	countRecords += ' AND ServicePlatform2__c != ' + '\'' + String.escapeSingleQuotes(servType) + '\'';
            }
            else if(tempValue=='Internet Dedicated +'){
                queryString += ' AND ServicePlatform2__c = ' + '\'' + String.escapeSingleQuotes(servType) + '\'';
            	countRecords += ' AND ServicePlatform2__c = ' + '\'' + String.escapeSingleQuotes(servType) + '\'';
            }
           
        }
		if(OrderType != 'None')
		{
			if(Company == 'None' && Owner == 'None'){
                 queryString += ' AND AccountId IN :AccountIds';
            	 countRecords += ' AND AccountId IN :AccountIds';
            }
			queryString += ' AND VPS_OrderType__c = ' + '\''+ OrderType + '\'';
			countRecords += ' AND VPS_OrderType__c = ' + '\''+ OrderType + '\'';
		}
       }
        
        //Add ORDER BY and LIMIT clauses to the end of the query.
        queryString += ' order by VPS_OrderFlag__c desc,createddate DESC LIMIT :rowLimit OFFSET :rowOffset';
        
        //Use Database.query with the created String to search using a dynamic query.
        orderlist = Database.query(queryString);
		//vrd changes start
		List<Order> orderlist1 = new List<Order>();
            if(tempValue=='Internet Dedicated Ethernet'){
                for(Order qList : orderlist) {
					if((qList.Quote.Description != '' || qList.Quote.Description!= null)){
						if(qList.Quote.Description == 'VRD') {
							
						}else{
                        	orderlist1.add(qList);
                    	}
                    }else{
                        orderlist1.add(qList);
                    }
				}
                orderlist.clear();
				orderlist=orderlist1.clone();
                
            }
            
            if(tempValue == 'Internet Dedicated +'){
				//quotelist.clear();
				for(Order qList : orderlist) {
                    //if(qList.contains('Description')){}
                    
					if((qList.Quote.Description != '' || qList.Quote.Description!= null)){
						if(qList.Quote.Description == 'VRD') {
							orderlist1.add(qList);
						}else{
                        
                    	}
                    }
				}
                orderlist.clear();
				orderlist=orderlist1.clone();
			}
		//vrd changes end
        
        wrapresponse.totalRecords = Database.countQuery(countRecords);
        wrapresponse.Orderdatalst = getOrderWrapList(orderlist,userRec.VPS_IsOrderingRole__c);
        
        return wrapresponse;
    }
    
    @AuraEnabled
    public static List<Account> getAccounts()
    {
        User currentUser = [SELECT Id, Name, contactId FROM User WHERE Id = :UserInfo.getUserId()];
        
        List<Account> returnList = new List<Account>();
	// IR 2990
        List<AccountContactRelation> accountContactJunction = [SELECT Id, accountId,account.Name,account.VPS_CLE_Name__c,account.VPS_Unique_NASP__c FROM AccountContactRelation WHERE contactid = :currentUser.contactId AND Account.RecordType.Name = 'Business' AND (Account.ACNA__c != '' OR Account.VPS_Unique_CLE_ID__c!='' OR Account.VPS_Unique_NASP__c !='')];
        // Account userAccount = [SELECT Id, Name, ParentId FROM Account WHERE Id = :accountContactJunction.accountId];
        String parentCLE = '';
        
        for(AccountContactRelation acc: accountContactJunction){
            Account acct = new Account();
            acct.Name = acc.account.Name;
            acct.VPS_CLE_Name__c = acc.account.VPS_CLE_Name__c;
            acct.Id =acc.account.id; //updated by ram.sahu
            returnList.add(acct);
        }
        
        
        return returnList;
    }
    
    @AuraEnabled
    public static List<User> getUsers()
    {
        List<User> relatedUsers = new List<User>();
        //Information on the currently logged in user is queried. 
        User loggedUser = [SELECT Id, Name, contactId FROM User WHERE Id = :UserInfo.getUserId()];
        //So that the currently logged in user shows up first, they are added to the list immediately.
        relatedUsers.add(loggedUser);
        
        AccountContactRelation accountContactJunction = [SELECT Id, accountId FROM AccountContactRelation WHERE contactid = :loggedUser.contactId AND IsDirect = true LIMIT 1];
        Account userAccount = [SELECT Id, Name, VPS_CLE_NAME__c, ParentId FROM Account WHERE Id = :accountContactJunction.accountId];
        
        List<Id> AccountIds = getAccountHierarchy();
        
        List<Id> relationIds = new List<Id>();
        for(AccountContactRelation acr : [SELECT Id, contactId FROM AccountContactRelation WHERE accountId IN :AccountIds])
        {
            relationIds.add(acr.contactId);
        }
        
        List<Id> contactIds = new List<Id>();
        for(Contact c : [SELECT Id, Name FROM Contact WHERE Id IN :relationIds])
        {
            contactIds.add(c.Id);
        }
        
        List<User> userList = [SELECT Id, Name, contactId FROM User WHERE contactId In :contactIds AND Id != :loggedUser.Id AND VPS_IsOrderingRole__c = true];
        for(User u : userList)
        {
            relatedUsers.add(u);
        }
        
        return relatedUsers;
    }
    
    @AuraEnabled
    public static List<String> getProducts()
    {
        
        // Changes for user story VPSCX-6774
        Schema.DescribeFieldResult productType = Order.VPS_Product_Type__c.getDescribe();
        List<Schema.picklistEntry> products = productType.getPicklistValues();
        List<String> options = new List<String>();
        List<String> finalList = new List<String>();
        for (Schema.picklistEntry p : products) {
            options.add(p.getValue());
        }
        
        if(!options.isEmpty()){
            options.sort();
            for(String str : options){
				finalList.add(str);
            }
             
        }
        return finalList;
        // End changes
    }
    
	//VBGSD-153 Start
	@AuraEnabled
    public static List<String> getOrderTypes()
    {
        Schema.DescribeFieldResult OrderType = Order.VPS_OrderType__c.getDescribe();
        List<Schema.picklistEntry> Ordertypes = OrderType.getPicklistValues();
        List<String> options = new List<String>();
        List<String> finalList = new List<String>();
        for (Schema.picklistEntry o : Ordertypes) {
            if(o.getValue() != 'Cancel' && o.getValue() != 'QuickOrder')
                options.add(o.getValue());
        }
        
        if(!options.isEmpty()){
            options.sort();
            for(String str : options){
				finalList.add(str);
            }
             
        }
        return finalList;
    }
	//VBGSD-153 End
	
    @AuraEnabled
    public static List<String> getHeaderProducts()
    {
        List<String> productList = new List<String>();
        List<Id> accountIds = getAccountHierarchy();
        //SOQL Query updated by CX Dev Team as per the discussion with Shop Team Date : 04 DEC 2019, 11:00 AM
        List<AggregateResult> orderList = [SELECT VPS_Product_Type__c  FROM Order WHERE VPS_Product_Type__c != '' AND VPS_Product_Type__c !='Switched Eline'  /* AND AccountId IN :accountIds*/ GROUP BY VPS_Product_Type__c ORDER BY VPS_Product_Type__c DESC]; 
        
        for(AggregateResult agr : orderList)
        {
            productList.add(String.valueOf(agr.get('VPS_Product_Type__c')));
        }
		//productList.add('Internet Dedicated +');//vrd changes
        productList.sort();
        return productList;
    }
    
    @AuraEnabled
    public static List<String> getHeaderProductOfferings()
    {
        List<String> productOfferingList = new List<String>();
        List<Id> accountIds = getAccountHierarchy();
        
       List<AggregateResult> orderList = [SELECT VPS_ProductOffering_WKL__c prod FROM Order WHERE VPS_ProductOffering_WKL__c != '' /*AND AccountId IN :accountIds*/ GROUP BY VPS_ProductOffering_WKL__c ORDER BY VPS_ProductOffering_WKL__c ASC];
        // List<AggregateResult> orderList = [SELECT ProductNameFormula__c prod FROM Quote WHERE ProductNameFormula__c != '' GROUP BY ProductNameFormula__c ORDER BY ProductNameFormula__c DESC];
        
        for(AggregateResult agr : orderList)
        {
            productOfferingList.add(String.valueOf(agr.get('prod')));
            
        }
        productOfferingList.sort();
        return productOfferingList;
    }
    //End of David's functions
    //This function returns the ids of all accouts in the hierarchy with which the user is associated, and is
    //used in several palces in the above three functions for use in an IN clause of an SOQL query
    /* 
    @AuraEnabled
    public static List<Id> getAccountHierarchy()
    {
        List<Id> returnList = new List<Id>();
        User loggedUser = [SELECT Id, Name, contactId FROM User WHERE Id = :UserInfo.getUserId()];
        List<AccountContactRelation> accountContactJunction = [SELECT Id, accountId FROM AccountContactRelation WHERE contactid = :loggedUser.contactId AND Account.RecordType.Name = 'Business' AND Account.VPS_Unique_CLE_ID__c != '' ];
        // Account userAccount = [SELECT Id, Name, ParentId, VPS_Parent_CLE_Id__c FROM Account WHERE Id = :accountContactJunction.accountId];
        //Start with user account, grab parentCLE or itself if none
        //Id parentCLE;
        for(AccountContactRelation acc: accountContactJunction){
            returnList.add(acc.accountId);
        }
        
        return returnList;
    }
    
    //End of David's functions
    */
    @AuraEnabled
    public static QuoteOrderWrap1 updateHeaderFilter(String header, String value, Integer rowLimit, Integer rowOffset)
    {
        header = String.escapeSingleQuotes(header); 
        value = String.escapeSingleQuotes(value);
        User userRec = [SELECT Id,VPS_IsDeliveryRole__c,VPS_IsOrderingRole__c FROM User WHERE Id = : UserInfo.getUserId()];
        
        List<Order> orderlist = new List<Order>();
        List<Id> AccountIds = getAccountHierarchy();
        
        QuoteOrderWrap1 wrapresponse = new QuoteOrderWrap1(); 
        if(header == 'VPS_Milestone_Status__c' && value == 'Activation1'){//[Start][SWARS]
	    // Added condition to filter record using createdById or ownerId
            List<List<sObject>> searchList = [FIND 'Activation' IN ALL FIELDS RETURNING Order(Id WHERE CreatedbyId= :UserInfo.getUserID() OR  ownerId= :UserInfo.getUserID())];
            
            Order[] searchOrders = (Order[])searchList[0];
            Set<Id> resultIds = new Set<Id>();
            for(Integer i = 0;i<searchOrders.size();i++)
                resultIds.add(searchOrders[i].Id);
            
            orderlist = [SELECT Quote.Description,Id, Omniscript_Instance_Id__c, VPS_OrderType__c, VPS_AssetId__c, VPS_Related_Order__c, QuoteId, VPS_ProductOffering_WKL__c, VPS_Product_Type__c, 
                         VPS_OrderFlag__c, VPS_Date_Submitted__c, VPS_Due_Date__c, OrderNumber, Name, VPS_Project_Id__c, Status, VPS_Milestone_Status__c, 
                         VPS_milestoneVsCompletionDate__c,ServicePlatform2__c, ProductName__c 
                         FROM Order WHERE Id in :resultIds AND Name !='Toll Free Name'];
            
            wrapresponse.totalRecords = resultIds.size();
            
        }
        else{//[End][SWARS]
            //Define the initial search query, which takes every field from the Order object.
            // Added threee FiledANme in SOQL for Revamp Project - Surendra  as  VPS_OrderType__c,VPS_AssetId__c,Vps_Related_Order__c
            /*
            String queryString = 'SELECT Id, VPS_OrderType__c,VPS_AssetId__c,Vps_Related_Order__c,Omniscript_Instance_Id__c,QuoteId,VPS_ProductOffering_WKL__c,VPS_Product_Type__c,VPS_OrderFlag__c,'
                + 'VPS_Date_Submitted__c,VPS_Due_Date__c ,OrderNumber,Name,VPS_Project_Id__c,status,VPS_Milestone_Status__c,ProductName__c,ServicePlatform2__c,VPS_milestoneVsCompletionDate__c FROM Order WHERE ' 
                + '(status IN (\'New\',\'Open\',\'Cancelled\',\'Submitted\',\'Completed\',\'Error\',\'Open\',\'Change Requested\') OR VPS_Milestone_Status__c IN (\'Acceptance\',\'Build\', \'FOC Summary\',\'Completion\', \'Network Evaluation\',\'Provisioning\') ) '
                + ' AND AccountId IN :accountIds AND (CreatedbyId=  \'' + userRec.Id  
                + '\' OR  ownerId= \'' + userRec.Id + '\')';
			*/
			String queryString;
            if((header == 'VPS_Product_Type__c' && value == 'Inbound Voice Services') || (header == 'VPS_ProductOffering_WKL__c' && value == 'US Toll Free') || (header == 'VPS_ProductOffering_WKL__c' && value == 'ITFS Toll Free') || (header == 'VPS_ProductOffering_WKL__c' && value == 'UIFN Toll Free')){
                queryString = 'SELECT Quote.Description,Id, VPS_OrderType__c,VPS_AssetId__c,Vps_Related_Order__c,Omniscript_Instance_Id__c,QuoteId,VPS_ProductOffering_WKL__c,VPS_Product_Type__c,VPS_OrderFlag__c,'
                + 'VPS_Date_Submitted__c,VPS_Due_Date__c ,OrderNumber,Name,VPS_Project_Id__c,status,VPS_Milestone_Status__c,ProductName__c,ServicePlatform2__c,VPS_milestoneVsCompletionDate__c FROM Order WHERE ' 
                + '(status IN (\'Open\',\'Cancelled\',\'Submitted\',\'Completed\',\'Error\',\'Jeopardy\',\'Open\',\'Change Requested\',\'In Progress\') OR VPS_Milestone_Status__c IN (\'Acceptance\',\'Build\', \'FOC Summary\',\'Completion\', \'Network Evaluation\',\'Provisioning\', \'Activation\') ) '                
                + ' AND (Name != \'Toll Free Name\') '
                + ' AND (AccountId IN :accountIds OR CreatedbyId=  \'' + userRec.Id  
                + '\' OR  ownerId= \'' + userRec.Id + '\')';
            }
            else{
                 queryString = 'SELECT Quote.Description,Id, VPS_OrderType__c,VPS_AssetId__c,Vps_Related_Order__c,Omniscript_Instance_Id__c,QuoteId,VPS_ProductOffering_WKL__c,VPS_Product_Type__c,VPS_OrderFlag__c,'
                + 'VPS_Date_Submitted__c,VPS_Due_Date__c ,OrderNumber,Name,VPS_Project_Id__c,status,VPS_Milestone_Status__c,ProductName__c,ServicePlatform2__c,VPS_milestoneVsCompletionDate__c FROM Order WHERE ' 
                + '(status IN (\'New\',\'Open\',\'Cancelled\',\'Submitted\',\'Completed\',\'Error\',\'Jeopardy\',\'Open\',\'Change Requested\',\'In Progress\') OR VPS_Milestone_Status__c IN (\'Acceptance\',\'Build\', \'FOC Summary\',\'Completion\', \'Network Evaluation\',\'Provisioning\', \'Activation\') ) '                
                + ' AND ((AccountId IN :accountIds) OR CreatedbyId=  \'' + userRec.Id  
                + '\' OR  ownerId= \'' + userRec.Id + '\')';
            }
            
            //countRecords is for lazy loading to set totalRecords
            String countRecords = 'SELECT COUNT() FROM Order WHERE  ' 
                + '(status IN (\'New\',\'Open\',\'Cancelled\',\'Submitted\',\'Completed\',\'Error\',\'Jeopardy\',\'Open\',\'Change Requested\',\'In Progress\') ' 
                +' OR VPS_Milestone_Status__c IN (\'Acceptance\',\'Build\', \'FOC Summary\',\'Completion\', \'Network Evaluation\',\'Provisioning\', \'Activation\') )'
                 + ' AND AccountId IN :accountIds AND (CreatedbyId=  \'' + userRec.Id  
                + '\' OR  ownerId= \'' + userRec.Id + '\')';
            
			String tempValue = value;
            if(value == 'Internet Dedicated +'){
               value = 'Internet Dedicated Ethernet';
			}
			//new VRD changes start
            if(value == 'IDS - Burstable'){
                value = 'IDE - Burstable';
            }
            if(value == 'IDS - Tiered'){
                value = 'IDE - Tiered';
            }
            //new VRD changes end
			String servType = 'VzB VRD';
            if(tempValue=='Internet Dedicated Ethernet'){
                queryString += ' AND ServicePlatform2__c != ' + '\'' + String.escapeSingleQuotes(servType) + '\'';
            	countRecords += ' AND ServicePlatform2__c != ' + '\'' + String.escapeSingleQuotes(servType) + '\'';
            }
            else if(tempValue=='Internet Dedicated +'){
                queryString += ' AND ServicePlatform2__c = ' + '\'' + String.escapeSingleQuotes(servType) + '\'';
            	countRecords += ' AND ServicePlatform2__c = ' + '\'' + String.escapeSingleQuotes(servType) + '\'';
            }
            queryString += ' AND ' + header + ' = \'' + value + '\'';
            countRecords += ' AND ' + header + ' = \'' + value + '\'';
            
            queryString += ' order by VPS_OrderFlag__c desc,createddate DESC LIMIT :rowLimit OFFSET :rowOffset';
            
            orderlist = Database.query(queryString);
			
			List<Order> orderlist1 = new List<Order>();
            if(tempValue=='Internet Dedicated Ethernet' || tempValue=='IDE - Tiered' || tempValue=='IDE - Burstable'){
                for(Order qList : orderlist) {
					if((qList.Quote.Description != '' || qList.Quote.Description!= null)){
						if(qList.Quote.Description == 'VRD') {
							
						}else{
                        	orderlist1.add(qList);
                    	}
                    }else{
                        orderlist1.add(qList);
                    }
				}
                orderlist.clear();
				orderlist=orderlist1.clone();
                
            }
            
            if(tempValue == 'Internet Dedicated +'|| tempValue=='IDS - Burstable' || tempValue=='IDS - Tiered'){
				//quotelist.clear();
				for(Order qList : orderlist) {
                    //if(qList.contains('Description')){}
                    
					if((qList.Quote.Description != '' || qList.Quote.Description!= null)){
						if(qList.Quote.Description == 'VRD') {
							orderlist1.add(qList);
						}else{
                        
                    	}
                    }
				}
                orderlist.clear();
				orderlist=orderlist1.clone();
			}
			
			
            
            wrapresponse.totalRecords = Database.countQuery(countRecords);            
        }
        wrapresponse.Orderdatalst = getOrderWrapList(orderlist,userRec.VPS_IsOrderingRole__c);
        
        return wrapresponse;
    }
    
    // For flag modal
    @AuraEnabled
    public static void flagOrder(String flagAction, String orderId) {
        Order order = [SELECT Id, VPS_OrderFlag__c FROM Order WHERE Id = :orderId];
        if (flagAction == 'flag') {
            order.VPS_OrderFlag__c = true;
        } else if (flagAction == 'unflag') {
            order.VPS_OrderFlag__c = false;
        }
        update order;
    }
    // for copy orders  Added By Mahesh M
    @AuraEnabled
    public static string copyorders(String orderId){  
        
        //  orderId = '8010x000001Fjoq';
        
        List<VPS_Quote_Order_Extension__c> extObjLst = new List<VPS_Quote_Order_Extension__c>();
        extObjLst = [Select id, name,VPS_Order__c,trackKey__c,layout__c,
                     OmnicancelAction__c, Omniframeembeded__c, isDTP__c,
                     sfdciFrameOrigin__c, sfdciFrameHost__c, Productid__c 
                     from VPS_Quote_Order_Extension__c where VPS_Order__c =:orderId];
        
        String productType =[select VPS_Product_Type__c from order where id =:orderId].VPS_Product_Type__c;
        String servicePlatform = [select  ServicePlatform2__c from order where id =:orderId].ServicePlatform2__c;
        //Added by Mahesh
        
        
        Map<string,string> urlParamsMap = new Map<string,string>();          
        urlParamsMap.put('ContextId','' );
        urlParamsMap.put('layout', '');
        urlParamsMap.put('trackKey', '');
        urlParamsMap.put('omniCancelAction', '');
        urlParamsMap.put('omniIframeEmbedded', '');
        urlParamsMap.put('isdtp', '');
        urlParamsMap.put('sfdcIFrameOrigin', '');
        urlParamsMap.put('sfdcIFrameHost', '');   
        urlParamsMap.put('productType', productType);  
        urlParamsMap.put('servicePlatform', servicePlatform);
        if(extObjLst != null && extObjLst.size() > 0){
            urlParamsMap.put('ContextId',extObjLst[0].Productid__c );
            urlParamsMap.put('layout', extObjLst[0].layout__c);
            urlParamsMap.put('trackKey', extObjLst[0].trackKey__c);
            urlParamsMap.put('omniCancelAction', extObjLst[0].OmnicancelAction__c);
            urlParamsMap.put('omniIframeEmbedded', extObjLst[0].Omniframeembeded__c);
            urlParamsMap.put('isdtp', extObjLst[0].isDTP__c);
            urlParamsMap.put('sfdcIFrameOrigin', extObjLst[0].sfdciFrameOrigin__c);
            urlParamsMap.put('sfdcIFrameHost', extObjLst[0].sfdciFrameHost__c);         
        }           
        string returnVal = JSON.serialize(urlParamsMap);
        
        return returnVal; 
    }
    
    
    /* Code added by CX dev Team */
    
    
 @AuraEnabled
    public static List<Id> getAccountHierarchy()
    {
        List<Id> returnList = new List<Id>();
        User loggedUser = [SELECT Id, Name, contactId FROM User WHERE Id = :UserInfo.getUserId()];
        /*List<AccountContactRelation> accountContactJunction = [SELECT Id, accountId FROM AccountContactRelation WHERE contactid = :loggedUser.contactId AND Account.RecordType.Name = 'Business' /*AND Account.ACNA__c != ''];*/
        List<AccountContactRelation> accountContactJunction = [SELECT Id, accountId FROM AccountContactRelation WHERE contactid = :loggedUser.contactId AND Account.RecordType.Name = 'Business'];
        for(AccountContactRelation acc: accountContactJunction){
            
            returnList.add(acc.accountId);
        }
        
        return returnList;
    } 
    @AuraEnabled
    public static QuoteOrderWrap1 getOrderListByProductNameStatus(String orderStatus,String productName,Integer rowLimit, Integer rowOffset) {
       
        
        List<Id> accountHIDs = getAccountHierarchy();        
        user userRec =   [SELECT Id,VPS_IsDeliveryRole__c,VPS_IsOrderingRole__c FROM User WHERE Id = : UserInfo.getUserId() limit 1];
        QuoteOrderWrap1 wrapresponse = new QuoteOrderWrap1();
        Set<Id> quoteId = new Set<Id>();
		if(userRec.VPS_IsOrderingRole__c ==true){
            List<Order> orderlist = new List<Order>();
                orderlist = [SELECT Id, VPS_OrderType__c,VPS_AssetId__c,Vps_Related_Order__c,Omniscript_Instance_Id__c,QuoteId,VPS_ProductOffering_WKL__c,VPS_OrderFlag__c,VPS_Date_Submitted__c 
                             ,VPS_Due_Date__c ,OrderNumber,Name,VPS_Project_Id__c,VPS_Product_Type__c,status,VPS_Milestone_Status__c,VPS_milestoneVsCompletionDate__c,ServicePlatform2__c,ProductName__c
                             FROM Order 
                             WHERE VPS_Product_Type__c =: productName 
                             AND Status =: orderStatus
                             AND AccountId IN : accountHIDs
                             AND  Name != 'Toll Free Name'
                             order by VPS_OrderFlag__c desc,createddate desc LIMIT :rowLimit OFFSET :rowOffset];
                wrapresponse.totalRecords = [SELECT COUNT() FROM Order where (CreatedbyId= :UserInfo.getUserID() OR  ownerId= :UserInfo.getUserID())];
            	wrapresponse.Orderdatalst = getOrderWrapList(orderlist,userRec.VPS_IsOrderingRole__c) ;
        }
        return wrapresponse;   
    }
 
}
