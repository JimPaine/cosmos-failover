using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Azure.Cosmos;
using Microsoft.Azure.Cosmos.Linq;

namespace src.Pages;

public class IndexModel : PageModel
{
    [Required]
    [Display(Name = "Partion Key")]
    public string? PartionKey { get; set; }

    [Required]
    public string? OtherData { get; set; }

    public List<Item> Items { get; set; } = new List<Item>();

    private readonly ILogger<IndexModel> logger;
    private readonly Container container;

    public IndexModel(
        ILogger<IndexModel> logger,
        Container container)
    {
        this.logger = logger;
        this.container = container;
        try
        {
            var query = this.container.GetItemLinqQueryable<Item>().ToFeedIterator();

            while (query.HasMoreResults)
            {
                foreach (var item in query.ReadNextAsync().Result)
                {
                    this.Items.Add(item);
                }
            }
        }
        catch (Exception e)
        {
            this.logger.LogError(e.InnerException?.Message ?? "Failed to query cosmos");
        }

    }

    public void OnGet() { }

    public async Task<IActionResult> OnPost(string PartionKey, string OtherData)
    {
        var item = new Item(Guid.NewGuid().ToString(), PartionKey, OtherData);
        var response = await this.container.CreateItemAsync(item, new PartitionKey(item.partionKey));

        this.Items.Add(item);
        return RedirectToPage();
    }
}

public record Item(string id, string partionKey, string otherData);
