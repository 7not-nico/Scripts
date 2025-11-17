use reqwest;
use tokio;

#[tokio::main]
async fn main() {
    let client = reqwest::Client::new();
    let mut handles = vec![];
    for i in 1..=100 {
        let client = client.clone();
        let handle = tokio::spawn(async move {
            download_book(client, i).await;
        });
        handles.push(handle);
    }
    for handle in handles {
        handle.await.unwrap();
    }
    println!("Download complete.");
}

async fn download_book(client: reqwest::Client, id: i32) {
    let filename = format!("book_{}.txt", id);
    if std::path::Path::new(&filename).exists() {
        return;
    }
    let url = format!("https://www.gutenberg.org/cache/epub/{}/pg{}.txt", id, id);
    match client.get(&url).send().await {
        Ok(resp) if resp.status().is_success() => {
            if let Ok(text) = resp.text().await {
                let _ = std::fs::write(&filename, text);
            }
        }
        _ => {}
    }
}