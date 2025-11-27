

from playwright.sync_api import sync_playwright

def crawl_subreddit(subreddit_name):
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False, slow_mo=500)
        page = browser.new_page()
        
        page.goto(f"https://old.reddit.com/r/{subreddit_name}")
        page.wait_for_selector('.thing')
        
        posts = []
        for post in page.query_selector_all('.thing'):
            comments = post.query_selector('.comments')
            if comments and 'comment' in comments.text_content().lower():
                link = comments.get_attribute('href')
                title = post.query_selector('.title a')
                if link and title:
                    posts.append({
                        'title': title.text_content(),
                        'link': f"https://old.reddit.com{link}" if link.startswith('/') else link
                    })
                    print(f"{title.text_content()}\n{posts[-1]['link']}\n")
        
        browser.close()
        return posts


if __name__ == "__main__":
    subreddit = input("Subreddit: ").strip() or "python"
    crawl_subreddit(subreddit)


