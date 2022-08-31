/******************************************************************************************
* Component:      VPS_QuoteWorklist_LightningDatatable
* @description    This class is used by the full worklist components and is in charge of 
*                 searching for the user's quotes and displaying them with the desired 
*                 filters and input
****************************************************************************************************************
Change Log:
11-OCT-2019      Edward Nguyen         Replace values for product offerings 
14-OCT-2019      Anthony               Replace values for product offerings 
15-OCT-2019      Edward Nguyen         PMD improved
18-OCT-2019      Dinesh Suggala        Added this VPS_IsQuoteSaved__c =true in where conditon as Suggested by pratyush

****************************************************************************************************************/
public without sharing class VPS_QuoteWorklist_LightningDatatable {
  @AuraEnabled
  public static List<Object> getSrvLocAddrActionLst() {
    List<Object> addr = new List<Object>();
    List<VPS_Service_Location__c> srvLocAddr = new List<VPS_Service_Location__c>();
    //List<String> evcAddrLst = new List<String>();
    //User u = [Select Id from User where username = 'bob.partneruser@mail.com'];
    String uId = userInfo.getUserId();
    List<Quote> q = [
      SELECT
        Id,
        GroupName__c,
        Group__r.Group_Id__c,
        Group__r.Catalog_Product_Relationship__r.Name,
        EVC_Full_Address__c,
        (SELECT Service_Location__r.Id FROM QuoteLineItems)
      FROM quote 
      WHERE  
        ownerId = :uId
        AND (VPS_Quote_Type__c = 'Install'
        OR VPS_Quote_Type__c = 'Change'
        OR VPS_Quote_Type__c = 'Disconnect'/*
        OR (VPS_Quote_Type__c = 'QuickOrder'
        AND Status = 'Complete')*/)
        AND MultiQuote__c = false
    ]; //u.Id];
    if (q.size() > 0) {
      Set<Id> servLocIds = new Set<Id>();
      for (Integer i = 0; i < q.size(); i++) {
        for (Integer j = 0; j < q[i].QuoteLineItems.size(); j++) {
          if (q[i].QuoteLineItems[j].Service_Location__r.Id != null) {
            servLocIds.add(q[i].QuoteLineItems[j].Service_Location__r.Id);
          }
        }
      }
      system.debug('servLocIds ==> ' + servLocIds);
      // Set<String> servAddrStr = new Set<String>();
      //
      if (!servLocIds.isEmpty()) {
        srvLocAddr = [
          SELECT uspsAddressExternal__c
          FROM VPS_Service_Location__c
          WHERE Id IN :servLocIds
        ];
        System.debug('srvLocAddr ====> ' + JSON.serializePretty(srvLocAddr));
      }
      Set<String> evcAddrLst = new Set<String>();
      for (Integer a = 0; a < q.size(); a++) {
        if (
          q[a].EVC_Full_Address__c != null &&
          q[a].EVC_Full_Address__c != ''
        ) {
          evcAddrLst.add(q[a].EVC_Full_Address__c);
        }
      }
      if (srvLocAddr.size() > 0) {
        addr.addAll(srvLocAddr);
        // addr.add(servAddrStr);
      }
      if (evcAddrLst.size() > 0) {
        addr.add(evcAddrLst);
      }
    }
    return addr;
    //return srvLocAddr;
  }

  @AuraEnabled
  public static List<Object> getgroupActionLst() {
    System.Debug('getgroupActionLst---');
    List<Object> quotegrp = new List<Object>();
    String uId = userInfo.getUserId();
    quotegrp = [
      SELECT
        Id,
        GroupName__c,
        Group__r.Group_Id__c,
        Group__r.Catalog_Product_Relationship__r.Name
      FROM Quote
      WHERE VPS_Quote_Type__c != 'QuickOrder' AND
        (ownerId = :uId
        OR createdbyid = :uId)
        AND MultiQuote__c = false
        AND VPS_IsQuoteSaved__c = true
    ];
    System.debug('quotegrp---' + JSON.serializePretty(quotegrp));
    return quotegrp;
  }

  @AuraEnabled
  public static QuoteOrderWrap1 getrecords1(
    String searchKey,
    String quoteStatus,
    Integer rowLimit,
    Integer rowOffset
  ) {
    System.debug('inside getrecords');
    System.debug('searchKey' + searchKey);
    System.debug('rowLimit: ' + rowLimit);
    System.debug('rowOffset: ' + rowOffset);
    if (searchKey == 'Internet Dedicated +') {
      searchKey = 'Internet Dedicated Ethernet';
    }
    QuoteOrderWrap1 wrapresponse = new QuoteOrderWrap1();
    List<Quote> quotelist = new List<Quote>();
    List<Id> accountHIDs = getAccountHierarchy();
    System.debug('accountHIDs was: ' + accountHIDs);
    List<Quote> quoteLocSearchLst = new List<Quote>(); //[SWARS]
    date quoteSearch;
    Boolean isDate = false;
         //Start - Modified/Added by Ashish || New Role changes || 4-02-2022
          User ouser = [SELECT 
                          contactId,Id,IsActive,Username,contact.name,accountId 
                          FROM User WHERE Id=:UserInfo.getUserId()];  
            Contact con = [SELECT Id,Name,AccountId,isSuperUser__c
                           FROM Contact 
                           WHERE id =:ouser.ContactId 
                           limit 1];
        //End - Modified/Added by Ashish || New Role changes || 4-02-2022
    try {
      System.debug('searchKey1 ' + searchKey);
      quoteSearch = date.parse(searchKey);
      isDate = true;
    } catch (exception e) {
      System.debug('Search key was not a date. This is not an error');
    }
    /*if (!Schema.SObjectType.Quote.isAccessible() ||
            !Schema.SObjectType.Quote.fields.QuoteNumber.isAccessible() ||
            !Schema.SObjectType.Quote.fields.Name.isAccessible() ||
            !Schema.SObjectType.Quote.fields.VPS_Product_Type__c.isAccessible() ||
            !Schema.SObjectType.Quote.fields.ProductName__c.isAccessible() ||
            !Schema.SObjectType.Quote.fields.EVC_Full_Address__c.isAccessible() ||
            !Schema.SObjectType.Quote.fields.Expiration_Date__c.isAccessible() ||
            !Schema.SObjectType.Quote.fields.Creation_Date__c.isAccessible() ||
            !Schema.SObjectType.Quote.fields.Status.isAccessible() ||
            !Schema.SObjectType.Quote.fields.PDF__c.isAccessible() ||
            !Schema.SObjectType.Quote.fields.VPS_QuoteFlag__c.isAccessible() ||
            !Schema.SObjectType.Quote.fields.VPS_Quote_Id__c.isAccessible() ||
            !Schema.SObjectType.Quote.fields.Omniscript_Instance_Id__c.isAccessible()) {
                return null; // error, insufficient permissions for query
            }*/
    if (isDate == true) {
      quotelist = [
        SELECT
          Id,
          Description,
          VPS_ICB__c,
          VPS_ServiceType__c,
          QuoteNumber,
          Name,
          GroupName__c,
          Group__r.Group_Id__c,
          Group__r.Catalog_Product_Relationship__r.Name,
          VPS_Product_Type__c,
          ProductNameFormula__c,
          EVC_Full_Address__c,
          Expiration_Date__c,
          Creation_Date__c,
          Status,
          PDF__c,
          VPS_QuoteFlag__c,
          VPS_Quote_Id__c,
          Omniscript_Instance_Id__c,
          (
            SELECT Id, Service_Location__r.uspsAddressExternal__c
            FROM QuoteLineItems
          )
        FROM Quote
        WHERE  
          (OwnerId= :UserInfo.getUserID() or createdbyid=:UserInfo.getUserID())  AND

          Creation_Date__c = :quoteSearch
          AND VPS_IsQuoteSaved__c = true
          AND MultiQuote__c = false
          AND (VPS_Quote_Type__c = 'Install'
          OR VPS_Quote_Type__c = 'Change'
          OR VPS_Quote_Type__c = 'Disconnect'/*
          OR (VPS_Quote_Type__c = 'QuickOrder'
          AND Status = 'Complete')*/)
        ORDER BY VPS_QuoteFlag__c DESC, Creation_Date__c DESC
        LIMIT :rowLimit
        OFFSET :rowOffset
      ];
      wrapresponse.totalRecords = [
        SELECT COUNT()
        FROM Quote
        WHERE VPS_Quote_Type__c != 'QuickOrder' AND 
          (OwnerId = :UserInfo.getUserID()
          OR createdbyid = :UserInfo.getUserID())
          AND VPS_IsQuoteSaved__c = true
          AND Creation_Date__c = :quoteSearch
      ];
    } else if (
      searchKey != null &&
      searchKey != '' &&
      String.isNotEmpty(quoteStatus)
    ) {
      System.debug('first else if');
      String keyForSearch = '%' + searchKey + '%';
      String keyForStringSearch = String.escapeSingleQuotes(searchKey);
      system.debug('In108' + keyForStringSearch.substring(0, 2));
      if (
        keyForStringSearch.substring(0, 3) == 'pt0' ||
        keyForStringSearch.substring(0, 3) == 'PT0' ||
        keyForStringSearch.substring(0, 3) == 'CPQ' ||
        keyForStringSearch.substring(0, 3) == 'cpq'
      ) {
        system.debug('In108If');
        keyForStringSearch = String.escapeSingleQuotes(searchKey);
      } else {
        keyForStringSearch = '';
      }
      keyForSearch = String.escapeSingleQuotes(keyForSearch);
      String keyForSearchQuoteStatus = '%' + quoteStatus + '%';
      keyForSearchQuoteStatus = String.escapeSingleQuotes(
        keyForSearchQuoteStatus
      );
      //below line commented by cx dev team
      //wrapresponse.totalRecords = [SELECT COUNT() FROM Quote WHERE (OwnerId= :UserInfo.getUserID() or createdbyid=:UserInfo.getUserID())  AND VPS_IsQuoteSaved__c = true AND Creation_Date__c = :quoteSearch AND (VPS_Quote_Type__c='Install' or VPS_Quote_Type__c='Change'or VPS_Quote_Type__c='Disconnect' or (VPS_Quote_Type__c='QuickOrder' AND Status ='Complete'))];
      quotelist = Database.query(
        'SELECT Id,Description,VPS_ICB__c,VPS_ServiceType__c, QuoteNumber,Name,GroupName__c,Group__r.Group_Id__c,Group__r.Catalog_Product_Relationship__r.Name,VPS_Product_Type__c,ProductNameFormula__c,EVC_Full_Address__c,Expiration_Date__c' +
        ',Creation_Date__c,Status,PDF__c,VPS_QuoteFlag__c,VPS_Quote_Id__c,Omniscript_Instance_Id__c,' +
        '(SELECT Id,Service_Location__r.uspsAddressExternal__c FROM QuoteLineItems) ' +
        'FROM Quote  WHERE VPS_Quote_Type__c != \'QuickOrder\' AND  (OwnerId= \'' +
        UserInfo.getUserID() +
        '\' or createdbyid= \'' +
        UserInfo.getUserID() +
        '\')  AND ' +
        '( Status like \'' +
        keyForSearchQuoteStatus +
        '\'' +
        ' AND VPS_Product_Type__c like \'' +
        keyForSearch +
        '\')' +
        ' AND MultiQuote__c = false' +
        ' AND VPS_IsQuoteSaved__c = true ' +
        'ORDER BY VPS_QuoteFlag__c DESC,Creation_Date__c DESC LIMIT ' +
        rowLimit +
        ' OFFSET ' +
        rowOffset
      );

      //[Start][SWARS][Searching key in Service Location]
      List<List<sObject>> searchList = [
        FIND :searchKey
        IN ALL FIELDS
        RETURNING VPS_Service_Location__c(Id, uspsAddressExternal__c)
      ];
      System.debug('searchList location: ' + searchList);
      VPS_Service_Location__c[] searchServLoc = (VPS_Service_Location__c[]) searchList[0];
      System.debug('searchServLoc: ' + searchServLoc);
      Set<Id> serLocIds = new Set<Id>();
      for (VPS_Service_Location__c a : searchServLoc) {
        serLocIds.add(a.Id);
      }
      System.debug('serLocIds: ' + serLocIds);
      if (!serLocIds.isEmpty() && searchKey != 'TLS') {
        quoteLocSearchLst = [
          SELECT
            Id,
            Description,
            VPS_ICB__c,
            VPS_ServiceType__c,
            QuoteNumber,
            Name,
            GroupName__c,
            Group__r.Group_Id__c,
            Group__r.Catalog_Product_Relationship__r.Name,
            VPS_Product_Type__c,
            ProductNameFormula__c,
            EVC_Full_Address__c,
            Expiration_Date__c,
            Creation_Date__c,
            Status,
            PDF__c,
            VPS_QuoteFlag__c,
            VPS_Quote_Id__c,
            Omniscript_Instance_Id__c,
            (
              SELECT Id, Service_Location__r.uspsAddressExternal__c
              FROM QuoteLineItems
            )
          FROM Quote
          WHERE VPS_Quote_Type__c != 'QuickOrder' AND 
            (OwnerId = :UserInfo.getUserId()
            OR CreatedById = :UserInfo.getUserId())
            AND VPS_IsQuoteSaved__c = true
            AND MultiQuote__c = false
            AND Id IN (
              SELECT QuoteId
              FROM QuoteLineItem
              WHERE Service_Location__r.Id IN :serLocIds
            )
          LIMIT :rowLimit
          OFFSET :rowOffset
        ];

        Set<Quote> locSearchSet = new Set<Quote>(quoteLocSearchLst);
        locSearchSet.addAll(quoteList);
        for (Quote qTest : locSearchSet) {
          System.debug('Test Value Was: ' + qTest.Name);
        }
        quoteList = new List<Quote>(locSearchSet); //quoteList is being appended to over here
        System.debug('quoteLocSearchLst: ' + quoteLocSearchLst);
        System.debug('size of quoteLocSearchLst: ' + quoteLocSearchLst.size());
        System.debug('size of serLocIds: ' + searchServLoc.size());
        /*if(quoteLocSearchLst.size() > 0){ //This was commented out for a reason, quotes are being added to the list 
                    quotelist.addAll(quoteLocSearchLst);//above through a set. This is to avoid duplication of records, please leave
                }*/ //this section as is unless errors are being observed.
      }
      System.debug('size of quotelist: ' + quotelist.size());
      //Removed  OR EVC_Full_Address__c like:keyForSearch
      //String s = 'Stand';

      String keySearchModified = getProductOfferingSearch(keyForSearch);
      wrapresponse.totalRecords = [
        SELECT COUNT()
        FROM Quote
        WHERE VPS_Quote_Type__c != 'QuickOrder' AND 
          (OwnerId = :UserInfo.getUserID()
          OR createdbyid = :UserInfo.getUserID())
          AND VPS_IsQuoteSaved__c = true
          AND MultiQuote__c = false
          AND (Name LIKE :keyForSearch
          OR VPS_Product_Type__c LIKE :keyForSearch
          OR ProductNameFormula__c LIKE :keySearchModified
          OR Status LIKE :keyForSearch)
      ];
      //wrapresponse.totalRecords = quotelist.size();
      wrapresponse.totalRecords += [
        SELECT COUNT()
        FROM Quote
        WHERE VPS_Quote_Type__c != 'QuickOrder' AND 
          (OwnerId = :UserInfo.getUserID()
          OR createdbyid = :UserInfo.getUserID())
          AND VPS_IsQuoteSaved__c = true
          AND MultiQuote__c = false
          AND Id IN (
            SELECT QuoteId
            FROM QuoteLineItem
            WHERE Service_Location__r.Id IN :serLocIds
          )
      ];
      System.debug('totalRecords was: ' + wrapresponse.totalRecords);
      //[End][SWARS][Searching key in Service Location]
    } else if (searchKey != null && searchKey != '') {
      System.debug('second else if');
      String keyForSearch = '%' + searchKey + '%';
      String keyForStringSearch = String.escapeSingleQuotes(searchKey);
      system.debug('In108' + keyForStringSearch.substring(0, 2));
      if (
        keyForStringSearch.substring(0, 3) == 'pt0' ||
        keyForStringSearch.substring(0, 3) == 'PT0' ||
        keyForStringSearch.substring(0, 3) == 'CPQ' ||
        keyForStringSearch.substring(0, 3) == 'cpq'
      ) {
        system.debug('In108If');
        keyForStringSearch = String.escapeSingleQuotes(searchKey);
      } else {
        keyForStringSearch = '';
      }

      keyForSearch = String.escapeSingleQuotes(keyForSearch);
      System.debug('keyForSearch105: ' + keyForSearch);
      //Removed  OR EVC_Full_Address__c like:keyForSearch in below query
      // ProductName__c query translated.
      System.debug('UserInfo.getUserID() was: ' + UserInfo.getUserID());
      System.debug(
        'getProductOfferingSearchWhereClause was: ' +
        getProductOfferingSearchWhereClause(keyForSearch)
      );
            //Start - Added by Ashish || New Role changes || 4-2-2022
            string conditionalOwner;
            if(con.isSuperUser__c){
                conditionalOwner = 'AccountID IN: accountHIDs  AND ';
            }else{
                conditionalOwner = '(OwnerId= \'' + UserInfo.getUserID() +'\' or createdbyid= \'' +UserInfo.getUserID() + '\'  or AccountID IN: accountHIDs )  AND ';
            }
        //End - Added by Ashish || New Role changes || 4-2-2022
      quotelist = Database.query(
        'SELECT Id,Description,VPS_ServiceType__c,VPS_ICB__c, MultiQuote__c ,QuoteNumber,Name,GroupName__c,Group__r.Group_Id__c,Group__r.Catalog_Product_Relationship__r.Name,VPS_Product_Type__c,ProductNameFormula__c,EVC_Full_Address__c,Expiration_Date__c' +
        ',Creation_Date__c,Status,PDF__c,VPS_QuoteFlag__c,VPS_Quote_Id__c,Omniscript_Instance_Id__c,VPS_Quote_Type__c,' +
        '(SELECT Id,Service_Location__r.uspsAddressExternal__c FROM QuoteLineItems) ' +
                'FROM Quote  WHERE VPS_Quote_Type__c != \'QuickOrder\' AND '+ conditionalOwner + //Modified by Ashish || Added conditionalOwner || 4-2-2022
                '(QuoteNumber = \'' +
        keyForStringSearch +
        '\' OR name like \'' +
        keyForSearch +
        '\' OR vlocity_cmt__TrackingNumber__c like \'' +
        keyForSearch +
        '\' OR VPS_Product_Type__c like \'' +
        keyForSearch +
        '\' OR ' +
        getProductOfferingSearchWhereClause(keyForSearch) +
        ' OR Status like \'' +
        keyForSearch +
        '\' OR EVC_Full_Address__c like \'' +
        keyForSearch +
        '\' OR GroupName__c like \'' +
        keyForSearch +
        '\') ' +
        ' AND VPS_IsQuoteSaved__c = true AND MultiQuote__c = false ' +
        'ORDER BY VPS_QuoteFlag__c DESC,Creation_Date__c DESC LIMIT ' +
        rowLimit +
        ' OFFSET ' +
        rowOffset
      );
      //test
      List<Quote> quotelist1 = new List<Quote>();
      for (Quote list1 : quotelist) {
        if (
          list1.VPS_Quote_Type__c == 'Install' ||
          list1.VPS_Quote_Type__c == 'Change' ||
          list1.VPS_Quote_Type__c == 'Disconnect' ||
          list1.VPS_Quote_Type__c == 'QuickOrder' &&
          list1.Status == 'Complete'
        ) {
          //test
          quotelist1.add(list1);
        } else {
          if (list1.MultiQuote__c = true)
            quotelist1.add(list1);
        }
      }
      quotelist = quotelist1;
      //testend
      //Took out "AND VPS_IsQuoteSaved__c = true" because no results were being returned
      System.debug('quotelist122: ' + quotelist);
      System.debug('quotelist123 size was: ' + quotelist.size());
      //[Start][SWARS][Searching key in Service Location]
      List<List<sObject>> searchList = [
        FIND :searchKey
        IN ALL FIELDS
        RETURNING VPS_Service_Location__c(Id, uspsAddressExternal__c)
      ];
      System.debug('searchList location: ' + searchList);
      VPS_Service_Location__c[] searchServLoc = (VPS_Service_Location__c[]) searchList[0];
      System.debug('searchServLoc: ' + searchServLoc);
      Set<Id> serLocIds = new Set<Id>();
      for (VPS_Service_Location__c a : searchServLoc) {
        serLocIds.add(a.Id);
      }
      System.debug('serLocIds: ' + serLocIds);
      if (!serLocIds.isEmpty() && searchKey != 'TLS') {
        quoteLocSearchLst = [
          SELECT
            Id,
            Description,
            VPS_ServiceType__c,
            VPS_ICB__c,
            QuoteNumber,
            Name,
            GroupName__c,
            Group__r.Group_Id__c,
            Group__r.Catalog_Product_Relationship__r.Name,
            VPS_Product_Type__c,
            ProductNameFormula__c,
            EVC_Full_Address__c,
            Expiration_Date__c,
            Creation_Date__c,
            Status,
            PDF__c,
            VPS_QuoteFlag__c,
            VPS_Quote_Id__c,
            Omniscript_Instance_Id__c,
            (
              SELECT Id, Service_Location__r.uspsAddressExternal__c
              FROM QuoteLineItems
            )
          FROM Quote
          WHERE VPS_Quote_Type__c != 'QuickOrder' AND 
            (OwnerId = :UserInfo.getUserId()
            OR CreatedById = :UserInfo.getUserId())
            AND VPS_IsQuoteSaved__c = true
            AND MultiQuote__c = false
            AND (VPS_Quote_Type__c = 'Install'
            OR VPS_Quote_Type__c = 'Change'
            OR VPS_Quote_Type__c = 'Disconnect'
            OR (VPS_Quote_Type__c = 'QuickOrder'
            AND Status = 'Complete'))
            AND Id IN (
              SELECT QuoteId
              FROM QuoteLineItem
              WHERE Service_Location__r.Id IN :serLocIds
            )
          LIMIT :rowLimit
          OFFSET :rowOffset
        ];

        Set<Quote> locSearchSet = new Set<Quote>(quoteLocSearchLst);
        locSearchSet.addAll(quoteList);
        for (Quote qTest : locSearchSet) {
          System.debug('Test Value Was: ' + qTest.Name);
        }
        quoteList = new List<Quote>(locSearchSet); //quoteList is being appended to over here
        System.debug('quoteLocSearchLst: ' + quoteLocSearchLst);
        System.debug('size of quoteLocSearchLst: ' + quoteLocSearchLst.size());
        System.debug('size of serLocIds: ' + searchServLoc.size());
        /*if(quoteLocSearchLst.size() > 0){ //This was commented out for a reason, quotes are being added to the list 
                    quotelist.addAll(quoteLocSearchLst);//above through a set. This is to avoid duplication of records, please leave
                }*/ //this section as is unless errors are being observed.
      }
      System.debug('size of quotelist: ' + quotelist.size());
      //Removed  OR EVC_Full_Address__c like:keyForSearch
      //String s = 'Stand';

      String keySearchModified = getProductOfferingSearch(keyForSearch);
      wrapresponse.totalRecords = [
        SELECT COUNT()
        FROM Quote
        WHERE VPS_Quote_Type__c != 'QuickOrder' AND 
          (OwnerId = :UserInfo.getUserID()
          OR createdbyid = :UserInfo.getUserID())
          AND VPS_IsQuoteSaved__c = true
          AND MultiQuote__c = false
          AND (VPS_Quote_Type__c = 'Install'
          OR VPS_Quote_Type__c = 'Change'
          OR VPS_Quote_Type__c = 'Disconnect'
          OR (VPS_Quote_Type__c = 'QuickOrder'
          AND Status = 'Complete'))
          AND (Name LIKE :keyForSearch
          OR VPS_Product_Type__c LIKE :keyForSearch
          OR ProductNameFormula__c LIKE :keySearchModified
          OR Status LIKE :keyForSearch)
      ];
      //wrapresponse.totalRecords = quotelist.size();
      wrapresponse.totalRecords += [
        SELECT COUNT()
        FROM Quote 
        WHERE VPS_Quote_Type__c != 'QuickOrder' AND 
          (OwnerId = :UserInfo.getUserID()
          OR createdbyid = :UserInfo.getUserID())
          AND VPS_IsQuoteSaved__c = true
          AND MultiQuote__c = false
          AND Id IN (
            SELECT QuoteId
            FROM QuoteLineItem
            WHERE Service_Location__r.Id IN :serLocIds
          )
      ];
      System.debug('totalRecords was: ' + wrapresponse.totalRecords);
      //[End][SWARS][Searching key in Service Location]
    } else if (String.isEmpty(searchKey) && String.isNotEmpty(quoteStatus)) {
      System.debug('third else if');
      String keyForSearch = '%' + quoteStatus + '%';
      keyForSearch = String.escapeSingleQuotes(quoteStatus);
      System.debug('keyForSearch: ' + quoteStatus);

      quotelist = Database.query(
        'SELECT Id,Description,VPS_ICB__c,VPS_ServiceType__c, QuoteNumber,Name,GroupName__c,Group__r.Group_Id__c,Group__r.Catalog_Product_Relationship__r.Name,VPS_Product_Type__c,ProductNameFormula__c,EVC_Full_Address__c,Expiration_Date__c' +
        ',Creation_Date__c,Status,PDF__c,VPS_QuoteFlag__c,VPS_Quote_Id__c,Omniscript_Instance_Id__c,' +
        '(SELECT Id,Service_Location__r.uspsAddressExternal__c FROM QuoteLineItems) ' +
        'FROM Quote  WHERE VPS_Quote_Type__c != \'QuickOrder\' AND  (OwnerId= \'' +
        UserInfo.getUserID() +
        '\' or createdbyid= \'' +
        UserInfo.getUserID() +
        '\'  )  AND ' +
        ' Status like \'' +
        keyForSearch +
        '\'' +
        ' AND VPS_IsQuoteSaved__c = true AND MultiQuote__c = false' +
        ' ORDER BY VPS_QuoteFlag__c DESC,Creation_Date__c DESC LIMIT ' + //added space in query by Ashish feb 2/2/20222
        rowLimit +
        ' OFFSET ' +
        rowOffset
      );
      System.debug('quotelist: ' + quotelist);
      //[Start][SWARS][Searching key in Service Location]
      List<List<sObject>> searchList = [
        FIND :quoteStatus
        IN ALL FIELDS
        RETURNING VPS_Service_Location__c(Id, uspsAddressExternal__c)
      ];
      System.debug('searchList location: ' + searchList);
      VPS_Service_Location__c[] searchServLoc = (VPS_Service_Location__c[]) searchList[0];
      System.debug('searchServLoc: ' + searchServLoc);
      Set<Id> serLocIds = new Set<Id>();
      for (VPS_Service_Location__c a : searchServLoc) {
        serLocIds.add(a.Id);
      }
      System.debug('serLocIds: ' + serLocIds);
      if (!serLocIds.isEmpty() && quoteStatus != 'TLS') {
        quoteLocSearchLst = [
          SELECT
            Id,
            Description,
            VPS_ICB__c,
            VPS_ServiceType__c,
            QuoteNumber,
            Name,
            Group__r.Name,
            Group__r.Catalog_Product_Relationship__r.Name,
            VPS_Product_Type__c,
            ProductNameFormula__c,
            EVC_Full_Address__c,
            Expiration_Date__c,
            Creation_Date__c,
            Status,
            PDF__c,
            VPS_QuoteFlag__c,
            VPS_Quote_Id__c,
            Omniscript_Instance_Id__c,
            (
              SELECT Id, Service_Location__r.uspsAddressExternal__c
              FROM QuoteLineItems
            )
          FROM Quote
          WHERE  
            (OwnerId = :UserInfo.getUserId()
            OR CreatedById = :UserInfo.getUserId())
            AND VPS_IsQuoteSaved__c = true
            AND MultiQuote__c = false
            AND (VPS_Quote_Type__c = 'Install'
            OR VPS_Quote_Type__c = 'Change'
            OR VPS_Quote_Type__c = 'Disconnect'/*
            OR (VPS_Quote_Type__c = 'QuickOrder'
            AND Status = 'Complete')*/)
            AND Id IN (
              SELECT QuoteId
              FROM QuoteLineItem
              WHERE Service_Location__r.Id IN :serLocIds
            )
          LIMIT :rowLimit
          OFFSET :rowOffset
        ];
        System.debug('quoteLocSearchLst: ' + quoteLocSearchLst);
        Set<Quote> locSearchSet = new Set<Quote>(quoteLocSearchLst);
        locSearchSet.addAll(quoteList);
        for (Quote qTest : locSearchSet) {
          System.debug('Test Value Was: ' + qTest.Name);
        }
        quoteList = new List<Quote>(locSearchSet); //quoteList is being appended to over here
        System.debug('quoteLocSearchLst: ' + quoteLocSearchLst);
        System.debug('size of quoteLocSearchLst: ' + quoteLocSearchLst.size());
        System.debug('size of serLocIds: ' + searchServLoc.size());
        /*if(quoteLocSearchLst.size() > 0){ //This was commented out for a reason, quotes are being added to the list 
                    quotelist.addAll(quoteLocSearchLst);//above through a set. This is to avoid duplication of records, please leave
                }*/ //this section as is unless errors are being observed.
      }
      System.debug('size of quotelist: ' + quotelist.size());
      //Removed  OR EVC_Full_Address__c like:keyForSearch
      //String s = 'Stand';

      String keySearchModified = getProductOfferingSearch(keyForSearch);
      wrapresponse.totalRecords = [
        SELECT COUNT()
        FROM Quote
        WHERE VPS_Quote_Type__c != 'QuickOrder' AND 
          (OwnerId = :UserInfo.getUserID()
          OR createdbyid = :UserInfo.getUserID())
          AND VPS_IsQuoteSaved__c = true
          AND MultiQuote__c = false
          AND (Name LIKE :keyForSearch
          OR VPS_Product_Type__c LIKE :keyForSearch
          OR ProductNameFormula__c LIKE :keySearchModified
          OR Status LIKE :keyForSearch
          OR vlocity_cmt__TrackingNumber__c LIKE :keyForSearch)
      ];
      //wrapresponse.totalRecords = quotelist.size();
      wrapresponse.totalRecords += [
        SELECT COUNT()
        FROM Quote 
        WHERE VPS_Quote_Type__c != 'QuickOrder' AND 
          (OwnerId = :UserInfo.getUserID()
          OR createdbyid = :UserInfo.getUserID())
          AND VPS_IsQuoteSaved__c = true
          AND MultiQuote__c = false
          AND Id IN (
            SELECT QuoteId
            FROM QuoteLineItem
            WHERE Service_Location__r.Id IN :serLocIds
          )
      ];
      System.debug('totalRecords was: ' + wrapresponse.totalRecords);
      //[End][SWARS][Searching key in Service Location]
    } else if (String.isEmpty(searchKey) && String.isNotEmpty(quoteStatus)) {
      String keyForSearch = '%' + quoteStatus + '%';
      keyForSearch = String.escapeSingleQuotes(quoteStatus);
      System.debug('keyForSearch: ' + quoteStatus);

      quotelist = Database.query(
        'SELECT Id,VPS_ICB__c, QuoteNumber,Name,GroupName__c,Group__r.Group_Id__c,Group__r.Catalog_Product_Relationship__r.Name,VPS_Product_Type__c,ProductNameFormula__c,EVC_Full_Address__c,Expiration_Date__c' +
        ',Creation_Date__c,Status,PDF__c,VPS_QuoteFlag__c,VPS_Quote_Id__c,Omniscript_Instance_Id__c,' +
        '(SELECT Id,Service_Location__r.uspsAddressExternal__c FROM QuoteLineItems) ' +
        'FROM Quote  WHERE VPS_Quote_Type__c != \'QuickOrder\' AND (OwnerId= \'' +
        UserInfo.getUserID() +
        '\' or createdbyid= \'' +
        UserInfo.getUserID() +
        '\'  )  AND ' +
        ' Status like \'' +
        keyForSearch +
        '\'' +
        ' AND VPS_IsQuoteSaved__c = true AND MultiQuote__c = false' +
        ' ORDER BY VPS_QuoteFlag__c DESC,Creation_Date__c DESC LIMIT ' + //Modified by Manav || Added space in query || 2/2/2022
        rowLimit +
        ' OFFSET ' +
        rowOffset
      );

      //[Start][SWARS][Searching key in Service Location]
      List<List<sObject>> searchList = [
        FIND :quoteStatus
        IN ALL FIELDS
        RETURNING VPS_Service_Location__c(Id, uspsAddressExternal__c)
      ];
      System.debug('searchList location: ' + searchList);
      VPS_Service_Location__c[] searchServLoc = (VPS_Service_Location__c[]) searchList[0];
      System.debug('searchServLoc: ' + searchServLoc);
      Set<Id> serLocIds = new Set<Id>();
      for (VPS_Service_Location__c a : searchServLoc) {
        serLocIds.add(a.Id);
      }
      System.debug('serLocIds: ' + serLocIds);
      if (!serLocIds.isEmpty() && quoteStatus != 'TLS') {
        quoteLocSearchLst = [
          SELECT
            Id,
            VPS_ServiceType__c,
            VPS_ICB__c,
            QuoteNumber,
            Name,
            GroupName__c,
            Group__r.Group_Id__c,
            Group__r.Catalog_Product_Relationship__r.Name,
            VPS_Product_Type__c,
            ProductNameFormula__c,
            EVC_Full_Address__c,
            Expiration_Date__c,
            Creation_Date__c,
            Status,
            PDF__c,
            VPS_QuoteFlag__c,
            VPS_Quote_Id__c,
            Omniscript_Instance_Id__c,
            (
              SELECT Id, Service_Location__r.uspsAddressExternal__c
              FROM QuoteLineItems
            )
          FROM Quote
          WHERE VPS_Quote_Type__c != 'QuickOrder' AND 
            (OwnerId = :UserInfo.getUserId()
            OR CreatedById = :UserInfo.getUserId())
            AND VPS_IsQuoteSaved__c = true
            AND MultiQuote__c = false
            AND Id IN (
              SELECT QuoteId
              FROM QuoteLineItem
              WHERE Service_Location__r.Id IN :serLocIds
            )
          LIMIT :rowLimit
          OFFSET :rowOffset
        ];

        Set<Quote> locSearchSet = new Set<Quote>(quoteLocSearchLst);
        locSearchSet.addAll(quoteList);
        for (Quote qTest : locSearchSet) {
          System.debug('Test Value Was: ' + qTest.Name);
        }
        quoteList = new List<Quote>(locSearchSet); //quoteList is being appended to over here
        System.debug('quoteLocSearchLst: ' + quoteLocSearchLst);
        System.debug('size of quoteLocSearchLst: ' + quoteLocSearchLst.size());
        System.debug('size of serLocIds: ' + searchServLoc.size());
        /*if(quoteLocSearchLst.size() > 0){ //This was commented out for a reason, quotes are being added to the list 
                    quotelist.addAll(quoteLocSearchLst);//above through a set. This is to avoid duplication of records, please leave
                }*/ //this section as is unless errors are being observed.
      }
      System.debug('size of quotelist: ' + quotelist.size());
      //Removed  OR EVC_Full_Address__c like:keyForSearch
      //String s = 'Stand';

      String keySearchModified = getProductOfferingSearch(keyForSearch);
      wrapresponse.totalRecords = [
        SELECT COUNT()
        FROM Quote
        WHERE VPS_Quote_Type__c != 'QuickOrder' AND 
          (OwnerId = :UserInfo.getUserID()
          OR createdbyid = :UserInfo.getUserID())
          AND VPS_IsQuoteSaved__c = true
          AND MultiQuote__c = false
          AND (Name LIKE :keyForSearch
          OR VPS_Product_Type__c LIKE :keyForSearch
          OR ProductNameFormula__c LIKE :keySearchModified
          OR Status LIKE :keyForSearch)
      ];
      //wrapresponse.totalRecords = quotelist.size();
      wrapresponse.totalRecords += [
        SELECT COUNT()
        FROM Quote 
        WHERE VPS_Quote_Type__c != 'QuickOrder' AND 
          (OwnerId = :UserInfo.getUserID()
          OR createdbyid = :UserInfo.getUserID())
          AND VPS_IsQuoteSaved__c = true
          AND MultiQuote__c = false
          AND Id IN (
            SELECT QuoteId
            FROM QuoteLineItem
            WHERE Service_Location__r.Id IN :serLocIds
          )
      ];
      System.debug('totalRecords was: ' + wrapresponse.totalRecords);
      //[End][SWARS][Searching key in Service Location]
    } else {
      System.debug('first else');
      System.debug('UserInfo.getUserID() was: ' + UserInfo.getUserID());

      /* quotelist =  [SELECT Id,VPS_ServiceType__c, VPS_ICB__c,QuoteNumber,Name,VPS_Product_Type__c,ProductNameFormula__c,EVC_Full_Address__c,Expiration_Date__c
                          ,Creation_Date__c,Status,PDF__c,VPS_QuoteFlag__c,VPS_Quote_Id__c,Omniscript_Instance_Id__c,VPS_Quote_Type__c,
                          (SELECT Id,Service_Location__r.uspsAddressExternal__c FROM QuoteLineItems)
                          FROM Quote  Where (OwnerId= :UserInfo.getUserID() or createdbyid=:UserInfo.getUserID()) AND VPS_IsQuoteSaved__c = true 
                          ORDER BY VPS_QuoteFlag__c DESC,Creation_Date__c DESC];// LIMIT :rowLimit OFFSET :rowOffset];*/
            //Start - Modified/Added by Ashish || New Role changes || 20-01-2022
          
            if(con.isSuperUser__c){
               /// SET<id> accHierIds = getRelatedAccounts(con.Account.Parent.Id);// pass the top cle account Id
               	List<Id> accHierIds = getAccountHierarchy();
                System.debug('accHierIds-->' +accHierIds);
                quotelist = [
                    SELECT
                    Id,
                    Description,
                    VPS_ServiceType__c,
                    VPS_ICB__c,
                    QuoteNumber,
                    Name,
                    AccountId, // End - - Modified/Added by Ashish || New Role changes || 20-01-2022
                    GroupName__c,
                    Group__r.Group_Id__c,
                    Group__r.Catalog_Product_Relationship__r.Name,
                    VPS_Product_Type__c,
                    ProductNameFormula__c,
                    EVC_Full_Address__c,
                    Expiration_Date__c,
                    Creation_Date__c,
                    Status,
                    PDF__c,
                    VPS_QuoteFlag__c,
                    VPS_Quote_Id__c,
                    Omniscript_Instance_Id__c,
                    VPS_Quote_Type__c,
                    (
                        SELECT Id, Service_Location__r.uspsAddressExternal__c
                        FROM QuoteLineItems
                    )
                    FROM Quote
                    WHERE VPS_Quote_Type__c != 'QuickOrder' AND 
                    (OwnerId = :UserInfo.getUserID()
                     OR createdbyid = :UserInfo.getUserID())
                    AND VPS_IsQuoteSaved__c = true
                    AND MultiQuote__c = false
                    AND AccountId IN :accHierIds //Added by Ashish
                    ORDER BY
                    GroupName__c DESC NULLS LAST,
                    VPS_QuoteFlag__c DESC,
                    Creation_Date__c DESC
                    LIMIT :rowLimit
                    OFFSET :rowOffset
                ];
                
                wrapresponse.totalRecords = [SELECT COUNT()
                                             FROM Quote
                                             WHERE VPS_Quote_Type__c != 'QuickOrder' AND 
                                             (OwnerId = :UserInfo.getUserID()
                                              OR createdbyid = :UserInfo.getUserID())
                                             AND VPS_IsQuoteSaved__c = true
                                             AND MultiQuote__c = false
                                             AND AccountId IN :accHierIds
                                            ];
            }
            else{  //END - Modified/Added by Ashish || New Role changes || 20-01-2022
                quotelist = [
                    SELECT
                    Id,
                    Description,
                    VPS_ServiceType__c,
                    VPS_ICB__c,
                    QuoteNumber,
                    Name,
                    GroupName__c,
                    Group__r.Group_Id__c,
                    Group__r.Catalog_Product_Relationship__r.Name,
                    VPS_Product_Type__c,
                    ProductNameFormula__c,
                    EVC_Full_Address__c,
                    Expiration_Date__c,
                    Creation_Date__c,
                    Status,
                    PDF__c,
                    VPS_QuoteFlag__c,
                    VPS_Quote_Id__c,
                    Omniscript_Instance_Id__c,
                    VPS_Quote_Type__c,
                    (
                        SELECT Id, Service_Location__r.uspsAddressExternal__c
                        FROM QuoteLineItems
                    )
                    FROM Quote
                    WHERE VPS_Quote_Type__c != 'QuickOrder' AND 
                    (OwnerId = :UserInfo.getUserID()
                     OR createdbyid = :UserInfo.getUserID())
                    AND VPS_IsQuoteSaved__c = true
                    AND MultiQuote__c = false
                    
                    /*AND (VPS_Quote_Type__c='Install' or VPS_Quote_Type__c='Change'or VPS_Quote_Type__c='Disconnect' or (VPS_Quote_Type__c='QuickOrder' AND Status ='Complete')) */
                    ORDER BY
                    GroupName__c DESC NULLS LAST,
                    VPS_QuoteFlag__c DESC,
                    Creation_Date__c DESC
                    LIMIT :rowLimit
                    OFFSET :rowOffset
                ];
                
                 wrapresponse.totalRecords = [
                SELECT COUNT()
                FROM Quote
                WHERE VPS_Quote_Type__c != 'QuickOrder' AND 
                (OwnerId = :UserInfo.getUserID()
                 OR createdbyid = :UserInfo.getUserID())
                AND VPS_IsQuoteSaved__c = true
                AND MultiQuote__c = false
                /*AND (VPS_Quote_Type__c='Install' or VPS_Quote_Type__c='Change'or VPS_Quote_Type__c='Disconnect' or (VPS_Quote_Type__c='QuickOrder' AND Status ='Complete')) */
            ];
       }
          
    }
    //WHERE ( (OwnerId =:UserInfo.getUserId() OR CreatedById=:UserInfo.getUserId()) )
    List<QuoteWrapper> quoteWrapList = new List<QuoteWrapper>();
    //Added for revamp project start
    List<VPS_Quote_Order_Extension__c> extObjLst = [
      SELECT
        id,
        name,
        VPS_Quote__c,
		VPS_Order__r.Id,
        trackKey__c,
        layout__c,
        OmnicancelAction__c,
        Omniframeembeded__c,
        isDTP__c,
        sfdciFrameOrigin__c,
        sfdciFrameHost__c,
        Product__c,
        Product__r.ProductCode,
        (
          SELECT Field_Name__c, Field_Value__c
          FROM VPS_Resume_Extentions__r
          WHERE Field_Name__c = 'OfferType_PTP'
        )
      FROM VPS_Quote_Order_Extension__c
      WHERE VPS_Quote__c = :quotelist
    ];
    system.debug('extObjLst&&&&&' + extObjLst);
    map<string, VPS_Quote_Order_Extension__c> quoteIdToExtnObjMap = new Map<string, VPS_Quote_Order_Extension__c>();
    for (VPS_Quote_Order_Extension__c eachExtnObj : extObjLst) {
      quoteIdToExtnObjMap.put(eachExtnObj.VPS_Quote__c, eachExtnObj);
    }
    system.debug('quoteIdToExtnObjMap---' + quoteIdToExtnObjMap);
    system.debug('quotelist&&&&&' + quotelist);
    //Added for revamp project end
    for (Quote quot : quotelist) {
      QuoteWrapper wrap = new QuoteWrapper();
      wrap.quote = quot;
      DateTime dt = (DateTime) quot.Creation_Date__c;
      //String formatteDdate = dt.format('MM/dd/yy');
      wrap.creationDate = dt.format('MM/dd/yy');
      if (!quot.QuoteLineItems.isEmpty()) {
        wrap.address = quot.QuoteLineItems[0]
          .Service_Location__r.uspsAddressExternal__c;
      }

      //Added for revamp project start
      wrap.layout = quoteIdToExtnObjMap.get(quot.id) != null
        ? quoteIdToExtnObjMap.get(quot.id).layout__c
        : '';
      wrap.trackKey = quoteIdToExtnObjMap.get(quot.id) != null
        ? quoteIdToExtnObjMap.get(quot.id).trackKey__c
        : '';
      wrap.omniCancelAction = quoteIdToExtnObjMap.get(quot.id) != null
        ? quoteIdToExtnObjMap.get(quot.id).OmnicancelAction__c
        : '';
      wrap.omniIframeEmbedded = quoteIdToExtnObjMap.get(quot.id) != null
        ? quoteIdToExtnObjMap.get(quot.id).Omniframeembeded__c
        : '';
      wrap.isdtp = quoteIdToExtnObjMap.get(quot.id) != null
        ? quoteIdToExtnObjMap.get(quot.id).isDTP__c
        : '';
      wrap.sfdcIFrameOrigin = quoteIdToExtnObjMap.get(quot.id) != null
        ? quoteIdToExtnObjMap.get(quot.id).sfdciFrameOrigin__c
        : '';
      wrap.sfdcIFrameHost = quoteIdToExtnObjMap.get(quot.id) != null
        ? quoteIdToExtnObjMap.get(quot.id).sfdciFrameHost__c
        : '';
	  wrap.orderID = (quoteIdToExtnObjMap.get(quot.id) != null && String.isNotBlank((String)quoteIdToExtnObjMap.get(quot.id).vps_Order__r.Id))
        ? (String)quoteIdToExtnObjMap.get(quot.id).vps_Order__r.Id
        : '';
      //wrap.productId = quoteIdToExtnObjMap.get(quot.id) != null ? quoteIdToExtnObjMap.get(quot.id).Productid__c : '';

      /*need to comment by cx dev team @11dec2019 21:21pm starts*/
      // wrap.productId = quoteIdToExtnObjMap.get(quot.id) != null ? quoteIdToExtnObjMap.get(quot.id).Product__c : null;
      //wrap.productCode =  (quoteIdToExtnObjMap.get(quot.id) != null && quoteIdToExtnObjMap.get(quot.id).Product__c != null)? quoteIdToExtnObjMap.get(quot.id).Product__r.ProductCode : '';
      //wrap.quoteId = quot.id;
      /*need to comment by cx dev team @11dec2019 21:21pm ends*/

      /*code updated by cx dev team starts*/
      string productId = '';
      if (quoteIdToExtnObjMap.get(quot.id) != null) {
        productId = quoteIdToExtnObjMap.get(quot.id).Product__c;
      }
      wrap.productId = productId;
      wrap.quoteId = quot.id;
      string productcode = '';
      if (
        quoteIdToExtnObjMap.get(quot.id) != null &&
        !String.isBlank(quoteIdToExtnObjMap.get(quot.id).Product__c)
      ) {
        productcode = quoteIdToExtnObjMap.get(quot.id).Product__r.ProductCode;
      }
      wrap.productCode = productcode;
      /*code updated by cx dev team ends*/
      wrap.VPSICB = (quot.VPS_ICB__c != true) ? 'false' : 'true';
      if (quot.VPS_ServiceType__c != null) {
        wrap.ServiceType = quot.VPS_ServiceType__c;
      }
      //Added for revamp project end

      /*VPS_Resume_Extention__c Resumeobj=  [select id, Field_Name__c, Field_Value__c from VPS_Resume_Extention__c where VPS_Quote_Order_Extension__c = :extObjLst[0].id and Field_Name__c='OfferType_PTP'];
               String OfferType='';    
            if(Resumeobj != null )
                    OfferType= Resumeobj.Field_Value__c;
            if(OfferType=='USPL')
            {
                wrap.disableCopy ='true';}
            else{
                wrap.disableCopy = 'false';}
            */

      //wrap.disableCopy = 'true';
      VPS_Quote_Order_Extension__c vqt = quoteIdToExtnObjMap.get(quot.id);
      if (
        vqt != null &&
        vqt.VPS_Resume_Extentions__r != null &&
        vqt.VPS_Resume_Extentions__r.size() > 0
      ) {
        if (vqt.VPS_Resume_Extentions__r[0].Field_Value__c == 'USPL')
          wrap.disableCopy = 'true';
      } else {
        wrap.disableCopy = 'false';
      }

      quoteWrapList.add(wrap);
    }
    wrapresponse.quotedatalst = quoteWrapList;
    System.debug('quoteWrapList size was: ' + quoteWrapList.size());
    System.debug(
      'wrapresponse.quotedatalst size was: ' + wrapresponse.quotedatalst.size()
    );
    wrapresponse.message = 'Quote records are loaded';
    wrapresponse.success = true;
    system.debug('wrapresponse==' + wrapresponse);
    return wrapresponse;
  }
  private static String getProductOfferingSearchWhereClause(String searchKey) {
    String poWhereClause =
      ' ( ProductNameFormula__c like \'' +
      searchKey +
      '\'';
    searchKey = searchKey.replace('%', '');
    String lowerSearchKey = searchKey.toLowerCase();
    if ('uni standalone'.contains(lowerSearchKey)) {
      poWhereClause += ' OR ProductNameFormula__c = \'ERS Premier UNI\' ';
    }
    //if('uni/evc combo'.contains(lowerSearchKey)) {
    if (('uni/evc combo'.contains(lowerSearchKey))) {
      // Added or condition for 2969_ITR_revert

      poWhereClause += ' OR ProductNameFormula__c = \'UNI EVC\' ';
    }
    if ('evc standalone'.contains(lowerSearchKey)) {
      poWhereClause += ' OR ProductNameFormula__c = \'ERS PREMIER EVC\' ';
    }
    /*if('Standalone'.contains(searchKey)) {
            poWhereClause += ' OR ProductNameFormula__c = \'ERS PREMIER EVC\' AND ProductNameFormula__c =\'UNI EVC\' AND ProductNameFormula__c =\'ERS Premier UNI\' ';
        }*/
    poWhereClause += ' )';
    return poWhereClause;
  }
  /*This method will update the product name in lazy loading  */
  private static String getProductOfferingSearch(String searchKey) {
    String poWhereClause = '';
    searchKey = searchKey.replace('%', '');
    String lowerSearchKey = searchKey.toLowerCase();
    if ('uni standalone'.contains(lowerSearchKey)) {
      poWhereClause = '%' + 'ERS' + '%';
    } else if ('uni/evc combo'.contains(lowerSearchKey)) {
      poWhereClause = '%' + 'UNI EVC' + '%';
    } else {
      return '%' + searchKey + '%';
    }
    return poWhereClause;
  }

  @AuraEnabled
  public static QuoteOrderWrap1 searchForIds(String searchText) {
    System.debug('searchText' + searchText);
    List<List<SObject>> results = [
      FIND :searchText
      IN ALL FIELDS
      RETURNING
        Quote(
          Id,
          QuoteNumber,
          Name,
          ProductNameFormula__c,
          EVC_Full_Address__c,
          Expiration_Date__c,
          Creation_Date__c,
          Status,
          PDF__c,
          VPS_QuoteFlag__c,
          Omniscript_Instance_Id__c),
        VPS_Service_Location__c(Id, uspsAddressExternal__c)
    ];
    System.debug('results ====> ' + results);
    List<Quote> ids = new List<Quote>();
    ids = ((List<Quote>) results[0]);
    System.debug('number of ids ====> ' + ids.size());
    Set<Id> qouteIds = new Set<Id>();
    if (ids.size() > 0) {
      for (Quote q : ids) {
        qouteIds.add(q.Id);
      }
    }

    System.debug('qouteIds ====> ' + qouteIds.size());
    /*if (!Schema.SObjectType.Quote.isAccessible() ||
            !Schema.SObjectType.Quote.fields.QuoteNumber.isAccessible() ||
            !Schema.SObjectType.Quote.fields.Name.isAccessible() ||
            !Schema.SObjectType.Quote.fields.VPS_Product_Type__c.isAccessible() ||
            !Schema.SObjectType.Quote.fields.ProductName__c.isAccessible() ||
            !Schema.SObjectType.Quote.fields.EVC_Full_Address__c.isAccessible() ||
            !Schema.SObjectType.Quote.fields.Expiration_Date__c.isAccessible() ||
            !Schema.SObjectType.Quote.fields.Creation_Date__c.isAccessible() ||
            !Schema.SObjectType.Quote.fields.Status.isAccessible() ||
            !Schema.SObjectType.Quote.fields.PDF__c.isAccessible() ||
            !Schema.SObjectType.Quote.fields.VPS_QuoteFlag__c.isAccessible() ||
            !Schema.SObjectType.Quote.fields.VPS_Quote_Id__c.isAccessible() ||
            !Schema.SObjectType.Quote.fields.Omniscript_Instance_Id__c.isAccessible()) {
                return null; // error, insufficient permissions for query
            }*/
    if (!qouteIds.isEmpty()) {
      List<Quote> quotelist = [
        SELECT
          Id,
          Description,
          VPS_ServiceType__c,
          VPS_ICB__c,
          QuoteNumber,
          Name,
          Group__c,
          ProductNameFormula__c,
          EVC_Full_Address__c,
          Expiration_Date__c,
          Creation_Date__c,
          Status,
          PDF__c,
          VPS_QuoteFlag__c,
          VPS_Quote_Id__c,
          Omniscript_Instance_Id__c,
          (
            SELECT Id, Service_Location__r.uspsAddressExternal__c
            FROM QuoteLineItems
          )
        FROM Quote
        WHERE VPS_Quote_Type__c != 'QuickOrder' AND 
          (OwnerId = :UserInfo.getUserID()
          OR createdbyid = :UserInfo.getUserID())
          AND Id IN :qouteIds
          AND VPS_IsQuoteSaved__c = true
          AND MultiQuote__c = false
      ];
      if (quotelist.size() > 0) {
        //ids.addAll(quotelist);
        ids = quotelist;
      }
    }

    List<Quote> quoteLocSearchLst = new List<Quote>();
    VPS_Service_Location__c[] searchServLoc = (VPS_Service_Location__c[]) results[1];
    System.debug('searchServLoc ====> ' + searchServLoc);
    Set<Id> serLocIds = new Set<Id>();
    for (VPS_Service_Location__c a : searchServLoc) {
      serLocIds.add(a.Id);
      System.debug('serLocIds ====> ' + serLocIds);
    }
    if (!serLocIds.isEmpty()) {
      System.debug('serLocIds.size ==> ' + serLocIds.Size());
      List<QuoteLineItem> qLnItems = [
        SELECT Id, QuoteId, Service_Location__r.uspsAddressExternal__c
        FROM QuoteLineItem
        WHERE Service_Location__r.Id IN :serLocIds
      ];
      System.debug('qLnItems ==> ' + qLnItems);
      Set<Id> qIds = new Set<Id>();
      for (QuoteLineItem qln : qLnItems) {
        qIds.add(qln.QuoteId);
      }
      System.debug('qIds ==> ' + qIds);
      quoteLocSearchLst = [
        SELECT
          Id,
          Description,
          VPS_ServiceType__c,
          VPS_ICB__c,
          QuoteNumber,
          Name,
          Group__c,
          ProductNameFormula__c,
          EVC_Full_Address__c,
          Expiration_Date__c,
          Creation_Date__c,
          Status,
          PDF__c,
          VPS_QuoteFlag__c,
          VPS_Quote_Id__c,
          Omniscript_Instance_Id__c,
          (
            SELECT Id, Service_Location__r.uspsAddressExternal__c
            FROM QuoteLineItems
          )
        FROM Quote
        WHERE VPS_Quote_Type__c != 'QuickOrder' AND 
          Id IN :qIds
          AND (OwnerId = :UserInfo.getUserID()
          OR createdbyid = :UserInfo.getUserID())
          AND VPS_IsQuoteSaved__c = true
          AND MultiQuote__c = false
      ];
      /* quoteLocSearchLst = [SELECT Id, QuoteNumber,Name,ProductName__c,EVC_Full_Address__c,Expiration_Date__c
,Creation_Date__c,Status,PDF__c,VPS_QuoteFlag__c,VPS_Quote_Id__c,Omniscript_Instance_Id__c,
(SELECT Id,Service_Location__r.uspsAddressExternal__c FROM QuoteLineItems where Service_Location__r.Id IN :serLocIds)
FROM Quote Where (OwnerId= :UserInfo.getUserID() or createdbyid=:UserInfo.getUserID())  AND VPS_IsQuoteSaved__c = true ];*/
      System.debug('quoteLocSearchLst size ====> ' + quoteLocSearchLst.size());
      if (quoteLocSearchLst.size() > 0) {
        if (ids.size() > 0) {
          ids.addAll(quoteLocSearchLst);
        } else {
          ids = quoteLocSearchLst;
        }
      }
    }

    List<QuoteWrapper> quoteWrapList = new List<QuoteWrapper>();
    //Added for revamp project start
    List<VPS_Quote_Order_Extension__c> extObjLst = [
      SELECT
        id,
        name,
        VPS_Quote__c,
		VPS_Order__r.Id,
        trackKey__c,
        layout__c,
        OmnicancelAction__c,
        Omniframeembeded__c,
        isDTP__c,
        sfdciFrameOrigin__c,
        sfdciFrameHost__c,
        Product__c,
        Product__r.ProductCode,
        (
          SELECT Field_Name__c, Field_Value__c
          FROM VPS_Resume_Extentions__r
          WHERE Field_Name__c = 'OfferType_PTP'
        )
      FROM VPS_Quote_Order_Extension__c
      WHERE VPS_Quote__c = :ids
    ];
    map<string, VPS_Quote_Order_Extension__c> quoteIdToExtnObjMap = new Map<string, VPS_Quote_Order_Extension__c>();
    for (VPS_Quote_Order_Extension__c eachExtnObj : extObjLst) {
      quoteIdToExtnObjMap.put(eachExtnObj.VPS_Quote__c, eachExtnObj);
    }
    system.debug('quoteIdToExtnObjMap---' + quoteIdToExtnObjMap);
    //Added for revamp project end

    for (Quote quot : ids) {
      QuoteWrapper wrap = new QuoteWrapper();
      wrap.quote = quot;
      System.debug('wrap.quote ====> ' + wrap.quote);
      DateTime dt = (DateTime) quot.Creation_Date__c;
      //String formatteDdate = dt.format('MM/dd/yy');
      wrap.creationDate = dt.format('MM/dd/yy');
      if (!quot.QuoteLineItems.isEmpty()) {
        wrap.address = quot.QuoteLineItems[0]
          .Service_Location__r.uspsAddressExternal__c;
        System.debug('wrap.Address ====> ' + wrap.address);
      }

      //Added for revamp project start
      wrap.layout = quoteIdToExtnObjMap.get(quot.id) != null
        ? quoteIdToExtnObjMap.get(quot.id).layout__c
        : '';
      wrap.trackKey = quoteIdToExtnObjMap.get(quot.id) != null
        ? quoteIdToExtnObjMap.get(quot.id).trackKey__c
        : '';
      wrap.omniCancelAction = quoteIdToExtnObjMap.get(quot.id) != null
        ? quoteIdToExtnObjMap.get(quot.id).OmnicancelAction__c
        : '';
      wrap.omniIframeEmbedded = quoteIdToExtnObjMap.get(quot.id) != null
        ? quoteIdToExtnObjMap.get(quot.id).Omniframeembeded__c
        : '';
      wrap.isdtp = quoteIdToExtnObjMap.get(quot.id) != null
        ? quoteIdToExtnObjMap.get(quot.id).isDTP__c
        : '';
      wrap.sfdcIFrameOrigin = quoteIdToExtnObjMap.get(quot.id) != null
        ? quoteIdToExtnObjMap.get(quot.id).sfdciFrameOrigin__c
        : '';
      wrap.sfdcIFrameHost = quoteIdToExtnObjMap.get(quot.id) != null
        ? quoteIdToExtnObjMap.get(quot.id).sfdciFrameHost__c
        : '';
      //wrap.productId = quoteIdToExtnObjMap.get(quot.id) != null ? quoteIdToExtnObjMap.get(quot.id).Productid__c : '';
      wrap.productId = quoteIdToExtnObjMap.get(quot.id) != null
        ? quoteIdToExtnObjMap.get(quot.id).Product__c
        : null;
      wrap.productCode = (quoteIdToExtnObjMap.get(quot.id) != null &&
        quoteIdToExtnObjMap.get(quot.id).Product__c != null)
        ? quoteIdToExtnObjMap.get(quot.id).Product__r.ProductCode
        : '';
	  wrap.orderID = (quoteIdToExtnObjMap.get(quot.id) != null && String.isNotBlank((String)quoteIdToExtnObjMap.get(quot.id).vps_Order__r.Id))
        ? (String)quoteIdToExtnObjMap.get(quot.id).vps_Order__r.Id
        : '';
      wrap.quoteId = quot.id;
      wrap.VPSICB = (quot.VPS_ICB__c != true) ? 'false' : 'true';
      if (quot.VPS_ServiceType__c != null) {
        wrap.ServiceType = quot.VPS_ServiceType__c;
      }
      VPS_Quote_Order_Extension__c vqt = quoteIdToExtnObjMap.get(quot.id);
      if (
        vqt.VPS_Resume_Extentions__r != null &&
        vqt.VPS_Resume_Extentions__r.size() > 0
      ) {
        if (vqt.VPS_Resume_Extentions__r[0].Field_Value__c == 'USPL')
          wrap.disableCopy = 'true';
      } else {
        wrap.disableCopy = 'false';
      }

      //Added for revamp project end
      quoteWrapList.add(wrap);
    }
    QuoteOrderWrap1 wrapresponse = new QuoteOrderWrap1();
    wrapresponse.quotedatalst = quoteWrapList;
    return wrapresponse;
  }
  //method for  groupName
  //QuoteOrderWrap1 wrapresponse = new QuoteOrderWrap1();
  //wrapresponse.groupName = groupNameList;
  //return wrapresponse;

  public class QuoteOrderWrap1 {
    @AuraEnabled
    public List<QuoteWrapper> quotedatalst;
    @AuraEnabled
    public Integer totalRecords = 0;
    @AuraEnabled
    public List<Quote> quoteList = new List<Quote>();
    @AuraEnabled
    public String message;

    @AuraEnabled
    public String disableCopy;
    @AuraEnabled
    public Boolean success;
    public QuoteOrderWrap1() {
      quotedatalst = new List<QuoteWrapper>();
    }
  }
  public class QuoteWrapper {
    @AuraEnabled
    public Quote quote;
    @AuraEnabled
    public String address;
    @AuraEnabled
    public String productOfferings;
    @AuraEnabled
    public String creationDate;
    //Added for Revamp project start
    @AuraEnabled
    public String layout;
    @AuraEnabled
    public String trackKey;
    @AuraEnabled
    public String omniCancelAction;
    @AuraEnabled
    public String omniIframeEmbedded;
    @AuraEnabled
    public String isdtp;
    @AuraEnabled
    public String sfdcIFrameOrigin;
    @AuraEnabled
    public String sfdcIFrameHost;
    @AuraEnabled
    public String productId;
    @AuraEnabled
    public String productCode;
    @AuraEnabled
    public String disableCopy;

    @AuraEnabled
    public String quoteId;
    //Added for Revamp project end
    @AuraEnabled
    public String productType;
    @AuraEnabled
    public String VPSICB;
    @AuraEnabled
    public String ServiceType;
	@AuraEnabled
    public String orderID;

    public QuoteWrapper() {
      quote = new Quote();
    }
  }

  @AuraEnabled(cacheable=true)
  public static string copyquotes(String quoteId) {
    // String omniscriptInstId;
    system.debug('Quote_Id ---' + quoteId);
    List<VPS_Quote_Order_Extension__c> extObjLst = new List<VPS_Quote_Order_Extension__c>();
    /* if (!Schema.SObjectType.VPS_Quote_Order_Extension__c.isAccessible() ||
            !Schema.SObjectType.VPS_Quote_Order_Extension__c.fields.name.isAccessible() ||
            !Schema.SObjectType.VPS_Quote_Order_Extension__c.fields.VPS_Quote__c.isAccessible() ||
            !Schema.SObjectType.VPS_Quote_Order_Extension__c.fields.trackKey__c.isAccessible() ||
            !Schema.SObjectType.VPS_Quote_Order_Extension__c.fields.layout__c.isAccessible() ||
            !Schema.SObjectType.VPS_Quote_Order_Extension__c.fields.OmnicancelAction__c.isAccessible() ||
            !Schema.SObjectType.VPS_Quote_Order_Extension__c.fields.Omniframeembeded__c.isAccessible() ||
            !Schema.SObjectType.VPS_Quote_Order_Extension__c.fields.isDTP__c.isAccessible() ||
            !Schema.SObjectType.VPS_Quote_Order_Extension__c.fields.OmnicancelAction__c.isAccessible() ||
            !Schema.SObjectType.VPS_Quote_Order_Extension__c.fields.sfdciFrameOrigin__c.isAccessible() ||
            !Schema.SObjectType.VPS_Quote_Order_Extension__c.fields.sfdciFrameHost__c.isAccessible() ||
            !Schema.SObjectType.VPS_Quote_Order_Extension__c.fields.Productid__c.isAccessible()) {
                return null; // error, insufficient permissions for query
            }*/

    extObjLst = [
      SELECT
        id,
        name,
        VPS_Quote__c,
        trackKey__c,
        layout__c,
        OmnicancelAction__c,
        Omniframeembeded__c,
        isDTP__c,
        sfdciFrameOrigin__c,
        sfdciFrameHost__c,
        Productid__c
      FROM VPS_Quote_Order_Extension__c
      WHERE VPS_Quote__c = :quoteId
    ];

    // String productType =[select VPS_Product_Type__c from quote where id =:quoteId].VPS_Product_Type__c; //Added by Mahesh
    // system.debug('productType       ^^'+productType);

    //chiru
    List<Quote> quoteObj = new List<Quote>();
    quoteObj = [
      SELECT VPS_Product_Type__c, VPS_ServiceType__c, Description
      FROM quote
      WHERE id = :quoteId
    ];
    System.debug('Product Type-->' + quoteObj[0].VPS_Product_Type__c);
    System.debug('Service Type-->' + quoteObj[0].VPS_ServiceType__c);
    System.debug('Description Type-->' + quoteObj[0].Description);
    //chiru ends

    Map<string, string> urlParamsMap = new Map<string, string>();
    urlParamsMap.put('ContextId', '');
    urlParamsMap.put('layout', '');
    urlParamsMap.put('trackKey', '');
    urlParamsMap.put('omniCancelAction', '');
    urlParamsMap.put('omniIframeEmbedded', '');
    urlParamsMap.put('isdtp', '');
    urlParamsMap.put('sfdcIFrameOrigin', '');
    urlParamsMap.put('sfdcIFrameHost', '');
    //urlParamsMap.put('productType', productType);
    urlParamsMap.put('productType', quoteObj[0].VPS_Product_Type__c);
    urlParamsMap.put('serviceType', quoteObj[0].VPS_ServiceType__c);
    if (quoteObj[0].Description == 'VRD' || quoteObj[0].Description == 'VRD') {
      urlParamsMap.put('servicePlatform', quoteObj[0].Description);
    } else {
      quoteObj[0].Description = 'Legacy';
      urlParamsMap.put('servicePlatform', quoteObj[0].Description);
    }

    if (extObjLst != null && extObjLst.size() > 0) {
      urlParamsMap.put('ContextId', extObjLst[0].Productid__c);
      urlParamsMap.put('layout', extObjLst[0].layout__c);
      urlParamsMap.put('trackKey', extObjLst[0].trackKey__c);
      urlParamsMap.put('omniCancelAction', extObjLst[0].OmnicancelAction__c);
      urlParamsMap.put('omniIframeEmbedded', extObjLst[0].Omniframeembeded__c);
      urlParamsMap.put('isdtp', extObjLst[0].isDTP__c);
      urlParamsMap.put('sfdcIFrameOrigin', extObjLst[0].sfdciFrameOrigin__c);
      urlParamsMap.put('sfdcIFrameHost', extObjLst[0].sfdciFrameHost__c);
    }
    string returnVal = JSON.serialize(urlParamsMap);
    system.debug('returnVal ---' + returnVal);
    return returnVal;
  }
  /*@AuraEnabled
public static QuoteOrderWrap1 loadQuoteRecords(Integer rowLimit,Integer rowOffset) {

List<Quote> quotelist = new List<Quote>();
quotelist =    [SELECT Id, QuoteNumber,Name,ProductName__c,EVC_Full_Address__c,Expiration_Date__c
,Creation_Date__c,Status,PDF__c,VPS_QuoteFlag__c,VPS_Quote_Id__c,Omniscript_Instance_Id__c,
(SELECT Id,Service_Location__r.uspsAddressExternal__c FROM QuoteLineItems)
FROM Quote Where (OwnerId= :UserInfo.getUserID() or createdbyid=:UserInfo.getUserID())  AND   VPS_IsQuoteSaved__c = true];
// LIMIT :rowLimit OFFSET :rowOffset        
List<QuoteWrapper> quoteWrapList = new List<QuoteWrapper>();
for(Quote quot : quotelist) {
QuoteWrapper wrap = new QuoteWrapper();
wrap.quote = quot;
DateTime dt = (DateTime)quot.Creation_Date__c;
//String formatteDdate = dt.format('MM/dd/yy');
wrap.creationDate = dt.format('MM/dd/yy');
if(!quot.QuoteLineItems.isEmpty()){
wrap.Address = quot.QuoteLineItems[0].Service_Location__r.uspsAddressExternal__c;
}
quoteWrapList.add(wrap);
}        
QuoteOrderWrap1 wrapresponse = new QuoteOrderWrap1();        
wrapresponse.quotedatalst = quoteWrapList;
wrapresponse.totalRecords = [SELECT COUNT() FROM Quote];
wrapresponse.message = 'Quote records are loaded';
wrapresponse.success = true;
// system.debug('wrapresponse=='+wrapresponse);        
return wrapresponse;
}*/

  //Start of David's functions
  //This function works similarly to getrecords1, except it changes the query for filtering
  //based on user provided parameters.
  @AuraEnabled
  public static QuoteOrderWrap1 updateRecords(
    String company,
    String owner,
    String product,
    Integer rowLimit,
    Integer rowOffset
  ) {
      //added for security issue--by apk
      company = String.escapeSingleQuotes(company);
      owner = String.escapeSingleQuotes(owner);
      product = String.escapeSingleQuotes(product);
      //ended
    QuoteOrderWrap1 wrapresponse = new QuoteOrderWrap1();
    List<Quote> quotelist = new List<Quote>();
    String tempValue = product;
    //This section will help determine which accounts are in the hierarchy with which the user is associated
    List<Id> accountIds = getAccountHierarchy();
    system.debug('accountIds@@@' + accountIds);
    system.debug('product@@@' + product);
    //Define the initial search query, which takes every field from the Quote object.
    //added Omniscript_Instance_Id__c field which is missing @06-June-2019 for fixing defect Worklist drilldown issue.(Hitesh has send the mail for it).
    /*if (!Schema.SObjectType.Quote.isAccessible() ||
            !Schema.SObjectType.Quote.fields.QuoteNumber.isAccessible() ||
            !Schema.SObjectType.Quote.fields.Name.isAccessible() ||
            !Schema.SObjectType.Quote.fields.VPS_Product_Type__c.isAccessible() ||
            !Schema.SObjectType.Quote.fields.ProductName__c.isAccessible() ||
            !Schema.SObjectType.Quote.fields.EVC_Full_Address__c.isAccessible() ||
            !Schema.SObjectType.Quote.fields.Expiration_Date__c.isAccessible() ||
            !Schema.SObjectType.Quote.fields.Creation_Date__c.isAccessible() ||
            !Schema.SObjectType.Quote.fields.Status.isAccessible() ||
            !Schema.SObjectType.Quote.fields.PDF__c.isAccessible() ||
            !Schema.SObjectType.Quote.fields.VPS_QuoteFlag__c.isAccessible() ||
            !Schema.SObjectType.Quote.fields.VPS_Quote_Id__c.isAccessible() ||
            !Schema.SObjectType.Quote.fields.Omniscript_Instance_Id__c.isAccessible()) {
                return null; // error, insufficient permissions for query
            }*/
    String queryString =
      'SELECT Id,Description,VPS_ServiceType__c,VPS_ICB__c, VPS_Product_Type__c,VPS_Quote_Type__c, QuoteNumber,Name,Omniscript_Instance_Id__c,VPS_QuoteFlag__c,ProductNameFormula__c,EVC_Full_Address__c,Expiration_Date__c,Creation_Date__c,' +
      'Status,PDF__c,(SELECT Id,Service_Location__r.uspsAddressExternal__c FROM QuoteLineItems) FROM Quote WHERE  VPS_Quote_Type__c != \'QuickOrder\' AND  VPS_IsQuoteSaved__c = true AND MultiQuote__c = false';

    // queryString += ' Id  !=\'\'';

    // + ' AccountId IN :accountIds'
    String countRecords = 'SELECT COUNT() FROM Quote WHERE VPS_Quote_Type__c != \'QuickOrder\' AND  VPS_IsQuoteSaved__c = true';
    // countRecords += ' Id  !=\'\'';
    //  + ' AccountId IN :accountIds'
    System.debug('Query string' + queryString);
    //Check to see which categories are being searched by,
    //values will be 'None' by default or if the user resets by a category.
    //
    if (company == 'None' && owner == 'None' && product == 'None') {
      queryString += ' AND AccountId IN :accountIds';
      countRecords += ' AND AccountId IN :accountIds';
    } else {
      if (company != 'None') {
        queryString += ' AND AccountId = ' + '\'' + company + '\'';
        countRecords += ' AND AccountId = ' + '\'' + company + '\'';
        System.debug('queryString@@@@@' + queryString);
        System.debug('countRecords@@@@@' + countRecords);
      }
      if (owner != 'None') {
        System.debug('Owner' + owner);
        queryString +=
          ' AND (CreatedById = ' +
          '\'' +
          owner +
          '\' OR OwnerId =  ' +
          '\'' +
          owner +
          '\')';
        countRecords +=
          ' AND (CreatedById = ' +
          '\'' +
          owner +
          '\' OR OwnerId =  ' +
          '\'' +
          owner +
          '\')';
        System.debug('queryString111@@@@@' + queryString);
        System.debug('countRecords111@@@@@' + countRecords);
      }
      if (product != 'None') {
        if (product == 'Internet Dedicated +') {
          product = 'Internet Dedicated Ethernet';
        }

        if (company == 'None' || owner == 'None') {
          queryString +=
            ' AND (AccountId IN :accountIds) AND VPS_Product_Type__c = ' +
            '\'' +
            product +
            '\'';
          countRecords +=
            ' AND( AccountId IN :accountIds) AND VPS_Product_Type__c = ' +
            '\'' +
            product +
            '\'';
          System.debug('queryString111product@@@@@' + queryString);
          System.debug('countRecords111products@@@@@' + countRecords);
        } else {
          queryString += ' AND VPS_Product_Type__c = ' + '\'' + product + '\'';
          countRecords += ' AND VPS_Product_Type__c = ' + '\'' + product + '\'';
          System.debug('queryString111product@@@@@' + queryString);
          System.debug('countRecords111products@@@@@' + countRecords);
        }
      }
    }

    //Add LIMIT clause to the end of the query.
    queryString += ' ORDER BY VPS_QuoteFlag__c DESC,Creation_Date__c DESC LIMIT :rowLimit OFFSET :rowOffset';

    //Use Database.query with the created String to search using a dynamic query.
    System.debug('Query string with order by and where clause' + queryString);
    quotelist = Database.query(queryString);

    List<Quote> quotelist1 = new List<Quote>();
    if (tempValue == 'Internet Dedicated Ethernet') {
      for (Quote qList : quotelist) {
        if (qList.Description != '' || qList.Description != null) {
          if (qList.Description == 'VRD') {
          } else {
            quotelist1.add(qList);
          }
        } else {
          quotelist1.add(qList);
        }
      }
      quotelist.clear();
      quotelist = quotelist1.clone();
    }
    if (tempValue == 'Internet Dedicated +') {
      //quotelist.clear();
      for (Quote qList : quotelist) {
        if (qList.Description != '' || qList.Description != null) {
          if (qList.Description == 'VRD') {
            quotelist1.add(qList);
          }
        }
      }
      quotelist.clear();
      quotelist = quotelist1.clone();
    }

    system.debug(quotelist.size() + 'size===>');
    //Added for revamp project start
    List<VPS_Quote_Order_Extension__c> extObjLst = [
      SELECT
        id,
        name,
        VPS_Quote__c,
		VPS_Order__r.Id,
        trackKey__c,
        layout__c,
        OmnicancelAction__c,
        Omniframeembeded__c,
        isDTP__c,
        sfdciFrameOrigin__c,
        sfdciFrameHost__c,
        Productid__c,
        Product__r.ProductCode
      FROM VPS_Quote_Order_Extension__c
      WHERE VPS_Quote__c = :quotelist
    ];
    map<string, VPS_Quote_Order_Extension__c> quoteIdToExtnObjMap = new Map<string, VPS_Quote_Order_Extension__c>();
    for (VPS_Quote_Order_Extension__c eachExtnObj : extObjLst) {
      quoteIdToExtnObjMap.put(eachExtnObj.VPS_Quote__c, eachExtnObj);
    }
    system.debug('quoteIdToExtnObjMap---' + quoteIdToExtnObjMap);
    //Added for revamp project end
    List<QuoteWrapper> wraplist = new List<QuoteWrapper>();

    for (Quote quot : quotelist) {
      QuoteWrapper wrap = new QuoteWrapper();
      wrap.quote = quot;
      DateTime dt = (DateTime) quot.Creation_Date__c;
      //String formatteDdate = dt.format('MM/dd/yy');
      wrap.creationDate = dt.format('MM/dd/yy');
      if (!quot.QuoteLineItems.isEmpty()) {
        wrap.address = quot.QuoteLineItems[0]
          .Service_Location__r.uspsAddressExternal__c;
      }
      //Added for revamp project start
      wrap.layout = quoteIdToExtnObjMap.get(quot.id) != null
        ? quoteIdToExtnObjMap.get(quot.id).layout__c
        : '';
      wrap.trackKey = quoteIdToExtnObjMap.get(quot.id) != null
        ? quoteIdToExtnObjMap.get(quot.id).trackKey__c
        : '';
      wrap.omniCancelAction = quoteIdToExtnObjMap.get(quot.id) != null
        ? quoteIdToExtnObjMap.get(quot.id).OmnicancelAction__c
        : '';
      wrap.omniIframeEmbedded = quoteIdToExtnObjMap.get(quot.id) != null
        ? quoteIdToExtnObjMap.get(quot.id).Omniframeembeded__c
        : '';
      wrap.isdtp = quoteIdToExtnObjMap.get(quot.id) != null
        ? quoteIdToExtnObjMap.get(quot.id).isDTP__c
        : '';
      wrap.sfdcIFrameOrigin = quoteIdToExtnObjMap.get(quot.id) != null
        ? quoteIdToExtnObjMap.get(quot.id).sfdciFrameOrigin__c
        : '';
      wrap.sfdcIFrameHost = quoteIdToExtnObjMap.get(quot.id) != null
        ? quoteIdToExtnObjMap.get(quot.id).sfdciFrameHost__c
        : '';
	  wrap.orderID = (quoteIdToExtnObjMap.get(quot.id) != null && String.isNotBlank((String)quoteIdToExtnObjMap.get(quot.id).vps_Order__r.Id))
        ? (String)quoteIdToExtnObjMap.get(quot.id).vps_Order__r.Id
        : '';
      //wrap.productId = quoteIdToExtnObjMap.get(quot.id) != null ? quoteIdToExtnObjMap.get(quot.id).Productid__c : '';
      wrap.productId = quoteIdToExtnObjMap.get(quot.id) != null
        ? quoteIdToExtnObjMap.get(quot.id).Product__c
        : null;
      wrap.productCode = (quoteIdToExtnObjMap.get(quot.id) != null &&
        quoteIdToExtnObjMap.get(quot.id).Product__c != null)
        ? quoteIdToExtnObjMap.get(quot.id).Product__r.ProductCode
        : '';
      wrap.quoteId = quot.id;
      //Added for revamp project end
      wrapList.add(wrap);
    }
    wrapresponse.quotedatalst = wrapList;
    wrapresponse.totalRecords = Database.countQuery(countRecords);
    wrapresponse.message = 'Quote records are loaded';
    wrapresponse.success = true;
    system.debug('wrapresponse==' + wrapresponse);
    return wrapresponse;
  }

  @AuraEnabled
  public static List<Account> getAccounts() {
    /*if (!Schema.SObjectType.User.isAccessible() ||
            !Schema.SObjectType.User.fields.Name.isAccessible() ||
            !Schema.SObjectType.User.fields.contactId.isAccessible()) {
                return null; // error, insufficient permissions for query
            }*/
    User currentUser = [
      SELECT Id, Name, contactId
      FROM User
      WHERE Id = :UserInfo.getUserId()
    ];
    System.debug('currentUser' + currentUser.contactId);
    List<Account> returnList = new List<Account>();
    // IR 2990
    List<AccountContactRelation> accountContactJunction = [
      SELECT
        Id,
        accountId,
        account.Name,
        account.VPS_CLE_Name__c,
        account.VPS_Unique_NASP__c
      FROM AccountContactRelation
      WHERE
        contactid = :currentUser.contactId
        AND Account.RecordType.Name = 'Business'
        AND (Account.ACNA__c != ''
        OR Account.VPS_Unique_CLE_ID__c != ''
        OR Account.VPS_Unique_NASP__c != '')
    ];
    // Account userAccount = [SELECT Id, Name, ParentId FROM Account WHERE Id = :accountContactJunction.accountId];
    String parentCLE = '';

    for (AccountContactRelation acc : accountContactJunction) {
      Account acct = new Account();
      acct.Name = acc.account.Name;
      acct.VPS_CLE_Name__c = acc.account.VPS_CLE_Name__c;
      acct.Id = acc.account.id; //updated by ram.sahu
      returnList.add(acct);
    }

    return returnList;
  }
  @AuraEnabled
  public static List<VPS_Group__c> getGroupNames() {
    system.debug('getGroup@@@');
    return [SELECT Id, Name, Account_ACNA__c FROM VPS_Group__c];
    //return[select id,name,Group__r.name from Quote];
  }

  @AuraEnabled
  public static List<User> getUsers() {
    List<User> relatedUsers = new List<User>();
    //Information on the currently logged in user is queried.
    /*if (!Schema.SObjectType.User.isAccessible() ||
            !Schema.SObjectType.User.fields.Name.isAccessible() ||
            !Schema.SObjectType.User.fields.contactId.isAccessible()) {
                return null; // error, insufficient permissions for query
            }*/
    User loggedUser = [
      SELECT Id, Name, contactId
      FROM User
      WHERE Id = :UserInfo.getUserId()
    ];
    //So that the currently logged in user shows up first, they are added to the list immediately.
    relatedUsers.add(loggedUser);

    AccountContactRelation accountContactJunction = [
      SELECT Id, accountId
      FROM AccountContactRelation
      WHERE contactid = :loggedUser.contactId AND IsDirect = true
      LIMIT 1
    ];
    Account userAccount = [
      SELECT Id, Name, VPS_CLE_NAME__c, ParentId
      FROM Account
      WHERE Id = :accountContactJunction.accountId
    ];

    List<Id> accountIds = getAccountHierarchy();

    List<Id> relationIds = new List<Id>();
    for (AccountContactRelation acr : [
      SELECT Id, contactId
      FROM AccountContactRelation
      WHERE accountId IN :accountIds
    ]) {
      relationIds.add(acr.contactId);
    }

    List<Id> contactIds = new List<Id>();
    for (Contact c : [SELECT Id, Name FROM Contact WHERE Id IN :relationIds]) {
      contactIds.add(c.Id);
    }

    List<User> userList = [
      SELECT Id, Name, contactId
      FROM User
      WHERE
        contactId IN :contactIds
        AND Id != :loggedUser.Id
        AND VPS_IsQuotingRole__c = true
    ];
    for (User u : userList) {
      relatedUsers.add(u);
    }

    return relatedUsers;
  }

  @AuraEnabled
  public static List<String> getProducts() {
    /*Set<String> productSet = new Set<String>();
        //find user account
        User loggedUser = [SELECT Id, Name, contactId FROM User WHERE Id = :UserInfo.getUserId()];
        AccountContactRelation accountContactJunction = [SELECT Id, accountId FROM AccountContactRelation WHERE contactid = :loggedUser.contactId AND IsDirect = true LIMIT 1];
        Account userAccount = [SELECT Id, Name, ParentId, VPS_Parent_CLE_Id__c FROM Account WHERE Id = :accountContactJunction.accountId];
        //Make a list of AccountIds, add user account, then add all related accounts
        List<Id> AccountIds = getAccountHierarchy();
        
        //cycle through the quotes associated with the account
        for(Quote q : [SELECT Id, Name, ProductName__c FROM Quote WHERE AccountId IN :AccountIds])
            //cycle through the quotes associated with the account
            //for(Quote q : [SELECT Id, Name, ProductName__c FROM Quote WHERE CreatedById = :UserInfo.getUserId() OR OwnerId = :UserInfo.getUserId()])
        {
            //check if the value is in the Set
            if(!productSet.contains(q.ProductName__c))
            {
                productSet.add(q.ProductName__c);
            }
        }
        
        //Copy the contents of the set into a list (AuraEnabled Functions do not allow sets to be returned)
        List<String> products = new List<String>(productSet);
        products.sort();
        for(integer i=0;i<products.size();i++)
            System.debug ('Index: ' + i + products[i]);
        return products;*/

    // Changes for User Story VPSCX-6774
    Schema.DescribeFieldResult productType = Quote.VPS_Product_Type__c.getDescribe();
    List<Schema.picklistEntry> products = productType.getPicklistValues();
    List<String> options = new List<String>();
    List<String> finalList = new List<String>();
    for (Schema.picklistEntry p : products) {
      options.add(p.getValue());
    }
    if (!options.isEmpty()) {
      options.sort();
      for (String str : options) {
        finalList.add(str);
      }
    }

    return finalList;
    // End changes
  }

  //This function returns the ids of all accouts in the hierarchy with which the user is associated, and is
  //used in several palces in the above three functions for use in an IN clause of an SOQL query
  @AuraEnabled
  public static List<Id> getAccountHierarchy() {
    List<Id> returnList = new List<Id>();
    User loggedUser = [
      SELECT Id, Name, contactId
      FROM User
      WHERE Id = :UserInfo.getUserId()
    ];
    List<AccountContactRelation> accountContactJunction = [
      SELECT Id, accountId
      FROM AccountContactRelation
      WHERE
        contactid = :loggedUser.contactId
        AND Account.RecordType.Name = 'Business' /* AND Account.ACNA__c != ''*/
    ];
    for (AccountContactRelation acc : accountContactJunction) {
      System.debug('The Id Was: ' + acc.accountId);
      returnList.add(acc.accountId);
    }

    return returnList;
  }

  //End of David's functions

  @AuraEnabled
  public static QuoteOrderWrap1 updateHeaderFilter(
    String header,
    String value,
    Integer rowLimit,
    Integer rowOffset //Need to do same changes in this methid too
  ) {
      //added for security issue-by apk
      header = String.escapeSingleQuotes(header);
      value = String.escapeSingleQuotes(value);
      //ended
    if (header != 'Service_Location__c') {
      User userRec = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
      List<Quote> quotelist = new List<Quote>();
      List<Id> accountIds = getAccountHierarchy();
      QuoteOrderWrap1 wrapresponse = new QuoteOrderWrap1();
      String countRecords;
      //Define the initial search query, which takes every field from the Order object.
      String queryString =
        'SELECT Id,Description,VPS_ServiceType__c,VPS_ICB__c, omniscript_instance_id__c, QuoteNumber,Name,Group__c,GroupName__c,Group__r.Group_Id__c,VPS_QuoteFlag__c,VPS_Product_Type__c,ProductNameFormula__c,EVC_Full_Address__c,Expiration_Date__c,Creation_Date__c,' +
        'Status,PDF__c,(SELECT Id,Service_Location__r.uspsAddressExternal__c FROM QuoteLineItems) FROM Quote ' +
        ' WHERE VPS_Quote_Type__c != \'QuickOrder\' AND (AccountId IN :accountIds) AND (CreatedbyId=  \'' +
        userRec.Id +
        '\' OR  ownerId= \'' +
        userRec.Id +
        '\')';

      //countRecords is for lazy loading to set totalRecords
      countRecords =
        'SELECT COUNT() FROM Quote ' +
        ' WHERE VPS_Quote_Type__c != \'QuickOrder\' AND (AccountId IN :accountIds) AND (CreatedbyId=  \'' +
        userRec.Id +
        '\' OR  ownerId= \'' +
        userRec.Id +
        '\')';
      String tempValue = value;
      if (value == 'Internet Dedicated +') {
        value = 'Internet Dedicated Ethernet';
      }
      //new VRD changes start
      if (value == 'IDS - Burstable') {
        value = 'IDE - Burstable';
      }
      if (value == 'IDS - Tiered') {
        value = 'IDE - Tiered';
      }
      if (value == 'IDS - Essential') {
        value = 'IDE - Essential';
      }
      //new VRD changes end

      queryString += ' AND ' + header + ' = \'' + value + '\'';
      countRecords += ' AND ' + header + ' = \'' + value + '\'';
      queryString += ' ORDER BY VPS_QuoteFlag__c desc,createddate DESC LIMIT :rowLimit OFFSET :rowOffset';
      System.debug('Query was: ' + queryString);
      quotelist = Database.query(queryString);
      System.debug('quotelist: ' + quotelist);

      List<Quote> quotelist1 = new List<Quote>();
      if (
        tempValue == 'Internet Dedicated Ethernet' ||
        tempValue == 'IDE - Tiered' ||
        tempValue == 'IDE - Burstable' ||
        tempValue == 'IDE - Essential'
      ) {
        for (Quote qList : quotelist) {
          if ((qList.Description != '' || qList.Description != null)) {
            if (qList.Description == 'VRD') {
            } else {
              quotelist1.add(qList);
            }
          } else {
            quotelist1.add(qList);
          }
        }
        quotelist.clear();
        quotelist = quotelist1.clone();
      }
      if (
        tempValue == 'Internet Dedicated +' ||
        tempValue == 'IDS - Burstable' ||
        tempValue == 'IDS - Tiered' ||
        tempValue == 'IDS - Essential'
      ) {
        //quotelist.clear();
        for (Quote qList : quotelist) {
          //if(qList.contains('Description')){}
          if ((qList.Description != '' || qList.Description != null)) {
            if (qList.Description == 'VRD') {
              quotelist1.add(qList);
            } else {
            }
          }
        }
        quotelist.clear();
        quotelist = quotelist1.clone();
      }
      System.debug('final quotelist: ' + quotelist);
      System.debug('quotelist1: ' + quotelist);
      System.debug('totalRecords: ' + Database.countQuery(countRecords));
      wrapresponse.totalRecords = Database.countQuery(countRecords);

      List<QuoteWrapper> wraplist = new List<QuoteWrapper>();
      //WHERE ( (OwnerId =:UserInfo.getUserId() OR CreatedById=:UserInfo.getUserId()) )
      List<QuoteWrapper> quoteWrapList = new List<QuoteWrapper>();
      //Added for revamp project start
      List<VPS_Quote_Order_Extension__c> extObjLst = [
        SELECT
          id,
          name,
          VPS_Quote__c,
		  VPS_Order__r.Id,
          trackKey__c,
          layout__c,
          OmnicancelAction__c,
          Omniframeembeded__c,
          isDTP__c,
          sfdciFrameOrigin__c,
          sfdciFrameHost__c,
          Product__c,
          Product__r.ProductCode,
          (
            SELECT Field_Name__c, Field_Value__c
            FROM VPS_Resume_Extentions__r
            WHERE Field_Name__c = 'OfferType_PTP'
          )
        FROM VPS_Quote_Order_Extension__c
        WHERE VPS_Quote__c = :quotelist
      ];
      map<string, VPS_Quote_Order_Extension__c> quoteIdToExtnObjMap = new Map<string, VPS_Quote_Order_Extension__c>();
      for (VPS_Quote_Order_Extension__c eachExtnObj : extObjLst) {
        quoteIdToExtnObjMap.put(eachExtnObj.VPS_Quote__c, eachExtnObj);
      }
      system.debug('quoteIdToExtnObjMap---' + quoteIdToExtnObjMap);
      //Added for revamp project end
      for (Quote quot : quotelist) {
        QuoteWrapper wrap = new QuoteWrapper();
        wrap.quote = quot;
        DateTime dt = (DateTime) quot.Creation_Date__c;
        //String formatteDdate = dt.format('MM/dd/yy');
        wrap.creationDate = dt.format('MM/dd/yy');
        if (!quot.QuoteLineItems.isEmpty()) {
          wrap.Address = quot.QuoteLineItems[0]
            .Service_Location__r.uspsAddressExternal__c;
        }
        //Added for revamp project start -Surendra
        wrap.layout = quoteIdToExtnObjMap.get(quot.id) != null
          ? quoteIdToExtnObjMap.get(quot.id).layout__c
          : '';
        wrap.trackKey = quoteIdToExtnObjMap.get(quot.id) != null
          ? quoteIdToExtnObjMap.get(quot.id).trackKey__c
          : '';
        wrap.omniCancelAction = quoteIdToExtnObjMap.get(quot.id) != null
          ? quoteIdToExtnObjMap.get(quot.id).OmnicancelAction__c
          : '';
        wrap.omniIframeEmbedded = quoteIdToExtnObjMap.get(quot.id) != null
          ? quoteIdToExtnObjMap.get(quot.id).Omniframeembeded__c
          : '';
        wrap.isdtp = quoteIdToExtnObjMap.get(quot.id) != null
          ? quoteIdToExtnObjMap.get(quot.id).isDTP__c
          : '';
        wrap.sfdcIFrameOrigin = quoteIdToExtnObjMap.get(quot.id) != null
          ? quoteIdToExtnObjMap.get(quot.id).sfdciFrameOrigin__c
          : '';
        wrap.sfdcIFrameHost = quoteIdToExtnObjMap.get(quot.id) != null
          ? quoteIdToExtnObjMap.get(quot.id).sfdciFrameHost__c
          : '';
		wrap.orderID = (quoteIdToExtnObjMap.get(quot.id) != null && String.isNotBlank((String)quoteIdToExtnObjMap.get(quot.id).vps_Order__r.Id))
        ? (String)quoteIdToExtnObjMap.get(quot.id).vps_Order__r.Id
        : '';
        //wrap.productId = quoteIdToExtnObjMap.get(quot.id) != null ? quoteIdToExtnObjMap.get(quot.id).Productid__c : '';
        wrap.productId = quoteIdToExtnObjMap.get(quot.id) != null
          ? quoteIdToExtnObjMap.get(quot.id).Product__c
          : null;
        wrap.productCode = (quoteIdToExtnObjMap.get(quot.id) != null &&
          quoteIdToExtnObjMap.get(quot.id).Product__c != null)
          ? quoteIdToExtnObjMap.get(quot.id).Product__r.ProductCode
          : '';
        wrap.quoteId = quot.id;
        //Added for revamp project end - Surendra
        VPS_Quote_Order_Extension__c vqt = quoteIdToExtnObjMap.get(quot.id);
        if (
          vqt != null &&
          vqt.VPS_Resume_Extentions__r != null &&
          vqt.VPS_Resume_Extentions__r.size() > 0
        ) {
          if (vqt.VPS_Resume_Extentions__r[0].Field_Value__c == 'USPL')
            wrap.disableCopy = 'true';
        } else {
          wrap.disableCopy = 'false';
        }
        wrapList.add(wrap);
      }

      wrapresponse.quotedatalst = wrapList;
      wrapresponse.totalRecords = Database.countQuery(countRecords);
      wrapresponse.message = 'Quote records are loaded';
      wrapresponse.success = true;
      system.debug('wrapresponse==' + wrapresponse);
      return wrapresponse;
    } else {
      List<List<SObject>> results = [
        FIND :value
        IN ALL FIELDS
        RETURNING
          Quote(
            Id,
            QuoteNumber,
            Name,
            ProductNameFormula__c,
            EVC_Full_Address__c,
            Expiration_Date__c,
            Creation_Date__c,
            Status,
            PDF__c,
            VPS_QuoteFlag__c,
            Omniscript_Instance_Id__c),
          VPS_Service_Location__c(Id, uspsAddressExternal__c)
      ];
      System.debug('results ====> ' + results);
      List<Quote> ids = new List<Quote>();
      ids = ((List<Quote>) results[0]);
      System.debug('number of ids ====> ' + ids.size());
      Set<Id> qouteIds = new Set<Id>();
      if (ids.size() > 0) {
        for (Quote q : ids) {
          qouteIds.add(q.Id);
        }
      }
      System.debug('qouteIds ====> ' + qouteIds.size());
      if (!qouteIds.isEmpty()) {
        List<Quote> quotelist = [
          SELECT
            Id,
            Description,
            VPS_ServiceType__c,
            VPS_ICB__c,
            QuoteNumber,
            Name,
            Group__c,
            ProductNameFormula__c,
            EVC_Full_Address__c,
            Expiration_Date__c,
            Creation_Date__c,
            Status,
            PDF__c,
            VPS_QuoteFlag__c,
            VPS_Quote_Id__c,
            Omniscript_Instance_Id__c,
            (
              SELECT Id, Service_Location__r.uspsAddressExternal__c
              FROM QuoteLineItems
            )
          FROM Quote
          WHERE VPS_Quote_Type__c != 'QuickOrder' AND 
            (OwnerId = :UserInfo.getUserID()
            OR createdbyid = :UserInfo.getUserID())
            AND Id IN :qouteIds
            AND VPS_IsQuoteSaved__c = true
            AND MultiQuote__c = false
        ];
        if (quotelist.size() > 0) {
          //ids.addAll(quotelist);
          ids = quotelist;
        }
      }

      List<Quote> quoteLocSearchLst = new List<Quote>();
      VPS_Service_Location__c[] searchServLoc = (VPS_Service_Location__c[]) results[1];
      System.debug('searchServLoc ====> ' + searchServLoc);
      Set<Id> serLocIds = new Set<Id>();
      for (VPS_Service_Location__c a : searchServLoc) {
        serLocIds.add(a.Id);
        System.debug('serLocIds ====> ' + serLocIds);
      }
      if (!serLocIds.isEmpty()) {
        System.debug('serLocIds.size ==> ' + serLocIds.Size());
        List<QuoteLineItem> qLnItems = [
          SELECT Id, QuoteId, Service_Location__r.uspsAddressExternal__c
          FROM QuoteLineItem
          WHERE Service_Location__r.Id IN :serLocIds
        ];
        System.debug('qLnItems ==> ' + qLnItems);
        Set<Id> qIds = new Set<Id>();
        for (QuoteLineItem qln : qLnItems) {
          qIds.add(qln.QuoteId);
        }
        System.debug('qIds ==> ' + qIds);
        quoteLocSearchLst = [
          SELECT
            Id,
            VPS_ServiceType__c,
            VPS_ICB__c,
            QuoteNumber,
            Name,
            Group__c,
            ProductNameFormula__c,
            EVC_Full_Address__c,
            Expiration_Date__c,
            Creation_Date__c,
            Status,
            PDF__c,
            VPS_QuoteFlag__c,
            VPS_Quote_Id__c,
            Omniscript_Instance_Id__c,
            (
              SELECT Id, Service_Location__r.uspsAddressExternal__c
              FROM QuoteLineItems
            )
          FROM Quote
          WHERE VPS_Quote_Type__c != 'QuickOrder' AND 
            Id IN :qIds
            AND (OwnerId = :UserInfo.getUserID()
            OR createdbyid = :UserInfo.getUserID())
            AND VPS_IsQuoteSaved__c = true
            AND MultiQuote__c = false
        ];
        System.debug(
          'quoteLocSearchLst size ====> ' + quoteLocSearchLst.size()
        );
        if (quoteLocSearchLst.size() > 0) {
          if (ids.size() > 0) {
            ids.addAll(quoteLocSearchLst);
          } else {
            ids = quoteLocSearchLst;
          }
        }
      }

      List<QuoteWrapper> quoteWrapList = new List<QuoteWrapper>();
      //Added for revamp project start
      List<VPS_Quote_Order_Extension__c> extObjLst = [
        SELECT
          id,
          name,
          VPS_Quote__c,
		  VPS_Order__r.Id,
          trackKey__c,
          layout__c,
          OmnicancelAction__c,
          Omniframeembeded__c,
          isDTP__c,
          sfdciFrameOrigin__c,
          sfdciFrameHost__c,
          Product__c,
          Product__r.ProductCode
        FROM VPS_Quote_Order_Extension__c
        WHERE VPS_Quote__c = :ids
      ];
      map<string, VPS_Quote_Order_Extension__c> quoteIdToExtnObjMap = new Map<string, VPS_Quote_Order_Extension__c>();
      for (VPS_Quote_Order_Extension__c eachExtnObj : extObjLst) {
        quoteIdToExtnObjMap.put(eachExtnObj.VPS_Quote__c, eachExtnObj);
      }
      system.debug('quoteIdToExtnObjMap---' + quoteIdToExtnObjMap);
      //Added for revamp project end

      for (Quote quot : ids) {
        QuoteWrapper wrap = new QuoteWrapper();
        wrap.quote = quot;
        System.debug('wrap.quote ====> ' + wrap.quote);
        DateTime dt = (DateTime) quot.Creation_Date__c;
        //String formatteDdate = dt.format('MM/dd/yy');
        wrap.creationDate = dt.format('MM/dd/yy');
        if (!quot.QuoteLineItems.isEmpty()) {
          wrap.address = quot.QuoteLineItems[0]
            .Service_Location__r.uspsAddressExternal__c;
          System.debug('wrap.Address ====> ' + wrap.address);
        }

        //Added for revamp project start
        wrap.layout = quoteIdToExtnObjMap.get(quot.id) != null
          ? quoteIdToExtnObjMap.get(quot.id).layout__c
          : '';
        wrap.trackKey = quoteIdToExtnObjMap.get(quot.id) != null
          ? quoteIdToExtnObjMap.get(quot.id).trackKey__c
          : '';
        wrap.omniCancelAction = quoteIdToExtnObjMap.get(quot.id) != null
          ? quoteIdToExtnObjMap.get(quot.id).OmnicancelAction__c
          : '';
        wrap.omniIframeEmbedded = quoteIdToExtnObjMap.get(quot.id) != null
          ? quoteIdToExtnObjMap.get(quot.id).Omniframeembeded__c
          : '';
        wrap.isdtp = quoteIdToExtnObjMap.get(quot.id) != null
          ? quoteIdToExtnObjMap.get(quot.id).isDTP__c
          : '';
        wrap.sfdcIFrameOrigin = quoteIdToExtnObjMap.get(quot.id) != null
          ? quoteIdToExtnObjMap.get(quot.id).sfdciFrameOrigin__c
          : '';
        wrap.sfdcIFrameHost = quoteIdToExtnObjMap.get(quot.id) != null
          ? quoteIdToExtnObjMap.get(quot.id).sfdciFrameHost__c
          : '';
        wrap.productId = quoteIdToExtnObjMap.get(quot.id) != null
          ? quoteIdToExtnObjMap.get(quot.id).Product__c
          : null;
        wrap.productCode = (quoteIdToExtnObjMap.get(quot.id) != null &&
          quoteIdToExtnObjMap.get(quot.id).Product__c != null)
          ? quoteIdToExtnObjMap.get(quot.id).Product__r.ProductCode
          : '';
		wrap.orderID = (quoteIdToExtnObjMap.get(quot.id) != null && String.isNotBlank((String)quoteIdToExtnObjMap.get(quot.id).vps_Order__r.Id))
        ? (String)quoteIdToExtnObjMap.get(quot.id).vps_Order__r.Id
        : '';
        wrap.quoteId = quot.id;
        //Added for revamp project end
        // Added - for USPL Copy Disable -- Start

        VPS_Quote_Order_Extension__c vqt = quoteIdToExtnObjMap.get(quot.id);
        if (
          vqt != null &&
          vqt.VPS_Resume_Extentions__r != null &&
          vqt.VPS_Resume_Extentions__r.size() > 0
        ) {
          if (vqt.VPS_Resume_Extentions__r[0].Field_Value__c == 'USPL')
            wrap.disableCopy = 'true';
        } else {
          wrap.disableCopy = 'false';
        }
        quoteWrapList.add(wrap);
      }
      QuoteOrderWrap1 wrapresponse = new QuoteOrderWrap1();
      wrapresponse.quotedatalst = quoteWrapList;
      return wrapresponse;
    }
  }

  // For flag modal
  @AuraEnabled
  public static void flagQuote(String flagAction, String quoteId) {
    Quote quote = [SELECT Id, VPS_QuoteFlag__c FROM Quote WHERE Id = :quoteId];
    if (flagAction == 'flag') {
      quote.VPS_QuoteFlag__c = true;
    } else if (flagAction == 'unflag') {
      quote.VPS_QuoteFlag__c = false;
    }
    update quote;
  }
}
