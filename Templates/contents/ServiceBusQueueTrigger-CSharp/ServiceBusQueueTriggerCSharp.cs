using System.IO;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Host;
using Microsoft.ServiceBus.Messaging;

namespace Company.Function
{
    public static class ServiceBusQueueTriggerCSharp
    {
        [FunctionName("FunctionNameValue")]                    
        public static void Run([ServiceBusTrigger("QueueNameValue", AccessRights.AccessRightsValue, Connection = "ConnectionValue")]string myQueueItem, TraceWriter log)
        {
            log.Info($"C# ServiceBus queue trigger function processed message: {myQueueItem}");
        }
    }
}