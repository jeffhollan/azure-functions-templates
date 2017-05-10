using System;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Host;

namespace Company.Function
{
    public static class QueueTriggerCSharp
    {
        [FunctionName("FunctionNameValue")]        
        public static void Run([QueueTrigger("PathValue", Connection = "ConnectionValue")]string myQueueItem, TraceWriter log)
        {
            log.Info($"C# Queue trigger function processed: {myQueueItem}");
        }
    }
}
