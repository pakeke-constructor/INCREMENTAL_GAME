

import time
from playwright.sync_api import sync_playwright



def crawl_post_comments(page, post_url):
    page.goto(post_url)
    page.wait_for_selector('.comment')
    
    comments = []
    for comment in page.query_selector_all('.comment'):
        author_elem = comment.query_selector('.author')
        body_elem = comment.query_selector('.usertext-body')
        score_elem = comment.query_selector('.score')
        
        if author_elem and body_elem:
            comments.append({
                'author': author_elem.text_content(),
                'content': body_elem.text_content().strip(),
                'upvotes': score_elem.text_content() if score_elem else '0'
            })
    
    return comments



def crawl_subreddit(page, subreddit_name, num_pages=3, sleep=3):
        page.goto(f"https://old.reddit.com/r/{subreddit_name}")
        
        posts = []
        for page_num in range(num_pages):
            page.wait_for_selector('.thing')
            
            for post in page.query_selector_all('.thing'):
                comments = post.query_selector('.comments')
                if comments and 'comment' in comments.text_content().lower():
                    link = comments.get_attribute('href')
                    title = post.query_selector('.title a')
                    if link and title:
                        link = f"https://old.reddit.com{link}" if link.startswith('/') else link
                        posts.append({
                            'title': title.text_content(),
                            'link': link
                        })

            next_button = page.query_selector('.next-button a')
            if not next_button:
                break

            time.sleep(sleep)
            next_button.click()
        
        browser.close()
        return posts


if __name__ == "__main__":
    subreddit = input("Subreddit: ").strip() or "python"

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False, slow_mo=500)
        page = browser.new_page()

        crawl_subreddit(page, subreddit, num_pages=10)

