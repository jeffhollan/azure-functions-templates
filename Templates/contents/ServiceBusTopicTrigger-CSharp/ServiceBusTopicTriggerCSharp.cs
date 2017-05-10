using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Host;
using Microsoft.ServiceBus.Messaging;

namespace Company.Function
{
    public static class ServiceBusTopicTriggerCSharp
    {
        [FunctionName("FunctionNameValue")]
        public static void Run([ServiceBusTrigger("TopicNameValue", "SubscriptionNameValue", AccessRights.AccessRightsValue, Connection = "ConnectionValue")]string mySbMsg, TraceWriter log)
        {
            log.Info($"C# ServiceBus topic trigger function processed message: {mySbMsg}");
        }
    }
}