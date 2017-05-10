using System.Linq;
using System.Net;
using System.Net.Http;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Azure.WebJobs.Host;
using Microsoft.WindowsAzure.Storage.Table;

namespace Company.Function
{
    public static class HttpGetCRUDCSharp
    {
        [FunctionName("FunctionNameValue")]
        public static HttpResponseMessage Run([HttpTrigger(AuthorizationLevel.AuthLevelValue, "get")]HttpRequestMessage req, [Table("TableNameValue", Connection = "ConnectionValue")]IQueryable<Person> inTable, TraceWriter log)
        {
            var query = from person in inTable select person;
            foreach (Person person in query)
            {
                log.Info($"Name:{person.Name}");
            }
            return req.CreateResponse(HttpStatusCode.OK, inTable.ToList());
        }

        public class Person : TableEntity
        {
            public string Name { get; set; }
        }
    }
}