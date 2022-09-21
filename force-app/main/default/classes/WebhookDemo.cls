@RestResource (urlMapping='/api/Webhooks/pushDetailsdemo/*')
global with sharing class WebhookDemo {
    public WebhookDemo() {

    }
    @HttpPost
    global static void handleNotification() {

        try{
            RestRequest request = RestContext.request;
            RestResponse response = RestContext.response;

            //fetching the body
            //get hash value from header
            string hashedVal = request.headers.get('X-Hub-Signature-256');
            system.debug('hashedval '+hashedval);
            Blob bB = request.requestBody;
            system.debug('blob: '+bB.toString());

            Blob hmac = Crypto.generateMac('hmacSHA256', bB, blob.valueOf('GHWebHkLc'));
            String hmacString = 'sha256='+EncodingUtil.convertToHex(hmac);
            system.debug('hmac:'+ EncodingUtil.convertToHex(hmac));

            if(hashedVal == hmacString)
            {
                system.debug('Secret value matched and source can be trusted');
                JSONParser parser = JSON.createParser(request.requestBody.toString());
                pusher ps;
                head_commit hc;
                string repo;
                while (parser.nextToken() != null)
                {
                    if (parser.getText() == 'pusher'){
                        system.debug('inside pusher');

                        parser.nextToken();
                        ps = (pusher)parser.readValueAs(pusher.class);
                        system.debug('ps '+ps);
                    }
                    if (parser.getText() == 'head_commit'){
                        system.debug('inside head commit');

                        parser.nextToken();
                        hc = (head_commit)parser.readValueAs(head_commit.class);
                        system.debug('hc '+hc);
                    }
                    if (parser.getText() == 'full_name'){
                        system.debug('inside full_name');

                        parser.nextToken();
                        repo = parser.getText();
                        system.debug('repo '+repo);
                    }
                }
                //Create GitHub_Push_Details__c based on received details
                GitHub_Push_detail__c detail = new GitHub_Push_detail__c();
                detail.Commiter_Name__c = ps!=null?ps.name:'';
                detail.Commiter_Email__c = ps!=null?ps.email:'';
                detail.Commit_Message__c = hc!=null?hc.message:'';
                Detail.Commit_TimeStamp__c = hc!=null?hc.timestamp:'';
                detail.Commited_URL__c = hc!=null?hc.url:'';
                detail.Rpository_Name__c = repo;
                detail.Added_Components__c = hc!=null&&hc.added!=null?String.join(hc.added,','):'';
                detail.Removed_Components__c = hc!=null&&hc.removed!=null?String.join(hc.removed,','):'';
                detail.Modified_Components__c = hc!=null&&hc.modified!=null?String.join(hc.modified, ','):'';
                insert detail;

                response.statusCode = 200;
                response.responseBody = Blob.valueOf(JSON.serialize(new SFDCResponse('Success', 'Processed Successfully')));

            }
            else{
                //set response as unauthorized
                response.statusCode = 401;
                response.responseBody = Blob.valueOf(JSON.serialize(new SFDCResponse('Failure','Not a valid Sender')));
            }
        }
        catch(Exception e){
            system.debug('Exception '+e.getMessage());

        }
    }
    public class SFDCResponse {
        String response;
        String message;

        public SFDCResponse (string resp, string msg){
            response = resp;
            message = msg;
        }
    }
    public class pusher {
        public string name;
        public string email;
        public pusher (String name, String email){
            name = name;
            email = email;
        }
    }
    public class head_commit {
        string message;
        string timestamp;
        string url;
        list<string> added;
        list<string> removed;
        list<string> modified;

        public head_commit(string hcmsg, string hc_timestamp, string hcUrl, list<string> hcadded, list<string> hcremoved, list<string> hcModified){
            message = hcmsg;
            timestamp = hc_timestamp;
            url = hcUrl;
            added = hcadded;
            removed = hcremoved;
            modified = hcModified;
        }
    }

}
