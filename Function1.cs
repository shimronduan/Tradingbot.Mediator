using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace Tradingbot.Mediator;

public class Function1
{
    private readonly ILogger<Function1> _logger;

    public Function1(ILogger<Function1> logger)
    {
        _logger = logger;
    }

    [Function("mediator")]
    public async Task<MultiResponse> Run([HttpTrigger(AuthorizationLevel.Function, "get", "post")] HttpRequest req)
    {

        string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
        if (requestBody=="wakeup")
        {
            return new MultiResponse()
            {
                HttpResponse = new OkObjectResult("Wakeup signal received.")
            };
        }
        _logger.LogInformation("C# HTTP trigger function processed a request. Request body: {RequestBody}", requestBody);
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