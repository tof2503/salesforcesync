public with sharing class SynchronisationHandler {
    
    public static SyncConfig getSyncConfig(String sourceObj, String destObj){

        String query = 'SELECT Id,Object_1__c,Object_2__c,Sync_key_Object_1__c,Sync_key_Object_2__c,(SELECT Id,Object_1_Field__c,Object_2_Field__c FROM Synchronisation_config_Fields__r) FROM SynchronisationConfig__mdt';

        List<SynchronisationConfig__mdt> lsync1 = (List<SynchronisationConfig__mdt>)Database.query(query + ' WHERE Object_1__c = \'' + sourceObj + '\' AND Object_2__c = \'' + destObj + '\'');
        List<SynchronisationConfig__mdt> lsync2 = (List<SynchronisationConfig__mdt>)Database.query(query + ' WHERE Object_2__c = \'' + sourceObj + '\' AND Object_1__c = \'' + destObj + '\'');

        List<SynchronisationConfig__mdt> mergedSyncList = new List<SynchronisationConfig__mdt>();
        
        if(lsync1 != null && lsync1.size() > 0) mergedSyncList.add(lsync1.get(0));
        if(lsync2 != null && lsync2.size() > 0) mergedSyncList.add(lsync2.get(0));
        
        SyncConfig sync = new SyncConfig();
        sync.fields = new List<SyncConfigField>();

        for(SynchronisationConfig__mdt s :mergedSyncList){
            Boolean obj1IsSource = s.Object_1__c.equals(sourceObj) ? true : false;

            sync.keyObjSource = obj1IsSource ? s.Sync_key_Object_1__c : s.Sync_key_Object_2__c;
            sync.keyObjDest = obj1IsSource ? s.Sync_key_Object_2__c : s.Sync_key_Object_1__c;
            
            for(Synchronisation_config_Field__mdt scf :s.Synchronisation_config_Fields__r){
                SyncConfigField fieldConf = new SyncConfigField();

                fieldConf.fieldSource = obj1IsSource ? scf.Object_1_Field__c : scf.Object_2_Field__c;
                fieldConf.fieldDest = obj1IsSource ? scf.Object_2_Field__c : scf.Object_1_Field__c;

                sync.fields.add(fieldConf);
            }
        }
        
        return sync;
    }

    public static void doSync(List<SObject> lSource, List<SObject> ldest){
        String sourceObjName = lSource.get(0).getSObjectType().getDescribe().getName();
        String destObjName = ldest.get(0).getSObjectType().getDescribe().getName();
        
        List<SObject> lObjToUpdate = new List<SObject>();
        Map<String,List<SObject>> mKeyLObject = new Map<String,List<SObject>>();

        SyncConfig syncConf = getSyncConfig(sourceObjName, destObjName);

        for(SObject obj :ldest){
            String keyValue = String.valueOf(obj.get(syncConf.keyObjDest));

            List<SObject> lObjects = mKeyLObject.containsKey(keyValue) ? mKeyLObject.get(keyValue) : new List<SObject>();
            lObjects.add(obj);
            mKeyLObject.put(keyValue, lObjects);
        }

        for(SObject obj :lSource){
            String keyValue = String.valueOf(obj.get(syncConf.keyObjSource));
            List<SObject> ldestObj = mKeyLObject.get(keyValue);

            for(SObject destObj :ldestObj){
                for(SyncConfigField currentField :syncConf.fields){
                    destObj.put(currentField.fieldDest,obj.get(currentField.fieldSource));
                }

                lObjToUpdate.add(destObj);
            }
        }

        if(lObjToUpdate.size() > 0) update lObjToUpdate;
    }


    public class SyncConfig{
        public String keyObjSource;
        public String keyObjDest;
        public List<SyncConfigField> fields;
    }

    public class SyncConfigField{
        public String fieldSource;
        public String fieldDest;
    }
}
