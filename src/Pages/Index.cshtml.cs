using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Azure.Cosmos;

namespace src.Pages;

public class IndexModel : PageModel
{
    [Required]
    [Display(Name = "Partion Key")]
    public string PartionKey { get; set; }

    [Required]
    public string OtherData { get; set; }

    private readonly ILogger<IndexModel> logger;
    private readonly Container container;

    public IndexModel(
        ILogger<IndexModel> logger,
        Container container)
    {
        this.logger = logger;
        this.container = container;

    }

    public void OnGet()
    {

    }

    public async Task<IActionResult> OnPost(string PartionKey, string OtherData)
    {
        var item = new Item(Guid.NewGuid().ToString(), PartionKey, OtherData);
        await this.container.CreateItemAsync(item, new PartitionKey(item.partionKey));
        return RedirectToPage();
    }
}

record Item(string id, string partionKey, string otherData);
