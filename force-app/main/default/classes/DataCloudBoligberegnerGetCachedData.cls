public class DataCloudBoligberegnerGetCachedData {

    @InvocableMethod(
        label='Get DataCloud boligberegning from Platform Cache' 
        description='Get cached boligberegning for supplied external IDs from Platform Cache')
    public static List<Boligberegning> getCachedData(List<String> externalIds) {
        // define results
        final List<Boligberegning> result = new List<Boligberegning>();
        
        // loop supplied IDs
        for (String externalId : externalIds) {
            final String cacheKey = DataCloudBoligberegnerInvocableAction.getCacheKey(externalId);
            final String jsonStr = (String)Cache.Org.get(cacheKey);
            final Map<String,Object> data = (Map<String,Object>)JSON.deserializeUntyped(jsonStr);
            final Boligberegning bb = new Boligberegning();
            bb.egenUdbetaling = (Integer)data.get('egenUdbetaling');
            bb.boligensPris = (Integer)data.get('boligensPris');
            result.add(bb);
        }
        
        // return
        return result;
    }

    public class Boligberegning {
		@InvocableVariable()
        public Integer egenUdbetaling;  
        
        @InvocableVariable()
        public Integer boligensPris;  
    }
}