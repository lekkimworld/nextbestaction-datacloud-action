public class DataCloudBoligberegnerInvocableAction {

    @InvocableMethod(
        label='Get boligberegning from DataCloud' 
        description='Get latest boligberegning for supplied account IDs')
    public static List<List<Recommendation>> getLatestBoligberegning(List<Id> accountIds) {
        // build result
        final List<List<Recommendation>> result = new List<List<Recommendation>>();
        
        // get a map of account ID to recommendation
        Map<String,Recommendation> data = getDataForAccountIDs(accountIds);
        for (Id accountId : accountIds) {
            // get the recommendation and see if there is one (we may not have one for 
            // the account)
            final Recommendation r = data.get(accountId);
            if (null != r) {
                System.debug('Adding recommendation to result for AccountId <' + accountID + '>');
                result.add(new List<Recommendation>{r});
            } else {
                System.debug('No recommendation to add for AccountId <' + accountID + '>');
                result.add(new List<Recommendation>());
            }
        }
        
        // return
        return result;
    }
    
    private static Map<String,Recommendation> getDataForAccountIDs(List<Id> accountIds) {
        // get accounts from ID's and build a map from PersonContactId back to Account Id
        final List<Account> accounts = [SELECT Id, PersonContactId FROM Account WHERE Id IN :accountIds];
        final List<Id> personAccountIds = new List<Id>();
        final Map<String,String> personContactIdMap = new Map<String,String>();
        for (Account a : accounts) {
            personAccountIds.add(a.PersonContactId);
            personContactIdMap.put(a.PersonContactId, a.Id);
        }
        
        // build query to get unified ID's from PersonContactId's
        final String t2QueryList = '\'' + String.join(personAccountIds, '\',\'') + '\'';
        final String t1QueryList = '(\'' + String.join(personAccountIds, '\', null), (\'') + '\', null)';
        final String unifiedRecordIdQuery = 'WITH t1 (SourceRecordId__c, c2) AS (VALUES ' + t1QueryList + '),  t2 (UnifiedRecordId__c, SourceRecordId__c) as (SELECT UnifiedRecordId__c, SourceRecordId__c FROM IndividualIdentityLink__dlm WHERE SourceRecordId__c IN (' + t2QueryList + ')) select t2.UnifiedRecordId__c, t1.SourceRecordId__c from t1 left outer join t2 on t1.SourceRecordId__c=t2.SourceRecordId__c';
		
        // invoke query and build list of unified ID's and a map to map from unified ID to PersonContactId
        ConnectApi.CdpQueryInput input = new ConnectApi.CdpQueryInput();
        input.sql = unifiedRecordIdQuery;
        ConnectApi.CdpQueryOutputV2 queryOutput = ConnectApi.CdPQuery.queryAnsiSqlV2(input);
        final Map<String,String> unifiedIdMap = new Map<String,String>();
        final List<String> unifiedIds = new List<String>();
        for (ConnectApi.CdpQueryV2Row row : queryOutput.data) {
            // add to list of unified IDs
            unifiedIds.add((String)row.rowData[0]);
            
            // map unified ID to PersonContactId
            unifiedIdMap.put((String)row.rowData[0], (String)row.rowData[1]);
        }
        
        // build engagement query
        final String sqlEngagementUnifiedIdFilter = '\'' + String.join(unifiedIds, '\',\'') + '\'';
        final String sqlEngagement = 'SELECT UnifiedRecordId__c, LastModifiedDate__c, Id__c, egenUdbetaling__c, boligensPris__c FROM Boliglaanberegner__dlm, IndividualIdentityLink__dlm WHERE Boliglaanberegner__dlm.Individual__c=IndividualIdentityLink__dlm.SourceRecordId__c AND UnifiedRecordId__c IN (' + sqlEngagementUnifiedIdFilter + ') order by UnifiedRecordId__c, LastModifiedDate__c desc';
        
        // get engagement data
        input = new ConnectApi.CdpQueryInput();
        input.sql = sqlEngagement;
        queryOutput = ConnectApi.CdPQuery.queryAnsiSqlV2(input);
        
        // loop
        final Map<String,Recommendation> result = new Map<String,Recommendation>();
        String currentId = null;
        for (ConnectApi.CdpQueryV2Row row : queryOutput.data) {
            if (null == currentId || !currentId.equals(row.rowData[0])) {
                // get Account Id from unified Id
                String personContactId = unifiedIdMap.get((String)row.rowData[0]);
                String accountId = personContactIdMap.get(personContactId);
                
                // build recommendation
                Recommendation r = new Recommendation(
                    ExternalId = (String)row.rowData[2],
                    Name = 'Boligberegner',
                    Description = 'Boligberegner usage by this customer',
                    ImageId = ID.valueOf('03SHo0000001GzAMAU'),
                	ActionReference = 'DataCloudBoligberegnerInvocableActionFlow',
                    AcceptanceLabel = 'Start calculations',
                    RejectionLabel = 'No Interest'
                );
                insert r;
                result.put(accountId, r);
                System.debug('Added recommendation for AccountId/ContactId <' + accountId + '> / <' + personContactId + '>');
                
                // add to platform cache
                final Map<String,Integer> data = new Map<String,Integer>{
                    'egenUdbetaling' => Integer.valueOf(row.rowData[3]),
                    'boligensPris' => Integer.valueOf(row.rowData[4])
                };
                final String jsonstr = JSON.serialize(data);
                final String cacheKey = getCacheKey((String)row.rowData[2]);
                Cache.Org.put(cacheKey, jsonstr, 3600, Cache.Visibility.ALL, true);
            }
            currentId = (String)row.rowData[0];
        }
        return result;
    }
    
    /**
     * Build a cache key from an external ID
     */
    public static String getCacheKey(String externalId) {
        final String cacheKey = 'local.DataCloudNBA.' + externalId.replaceAll('[-]', '');
        return cacheKey;
    }
    
}