using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace Tradingbot.Mediator;

public class Function1(ILogger<Function1> logger)
{
    private readonly ILogger<Function1> _logger = logger;

    [Function("Function1")]
    public async Task<MultiResponse> Run([HttpTrigger(AuthorizationLevel.Function, "get", "post")] HttpRequest req)
    {
        _logger.LogInformation("C# HTTP trigger function processed a request.");

        string requestBody = await new StreamReader(req.Body).ReadToEndAsync();

        return new MultiResponse()
        {
            Message = new MyQueueItem
            {
                Body = requestBody
            },
            HttpResponse = new OkObjectResult("Request body sent to queue.")
        };
    }
}

public class MultiResponse
{
    [QueueOutput("futures", Connection = "QueueConnection")]
    public MyQueueItem? Message { get; set; }

    [HttpResult]
    public IActionResult? HttpResponse { get; set; }
}

public class MyQueueItem
{
    public string? Body { get; set; }
}