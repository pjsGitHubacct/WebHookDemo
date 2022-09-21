@RestResource (urlMapping='/api/Webhooks/pushDetailsdemo/*')
global with sharing class WebhookDemo {
    public WebhookDemo() {

    }
    @HttpPost
    global static void handleNotification() {

        try{
            RestRequest request = RestContext.request;
            RestResponse response = RestContext.response;

        }
        catch(Exception e){
            system.debug('Exception '+e.getMessage());

        }
    }

}
