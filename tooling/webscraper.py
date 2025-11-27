
from playwright.sync_api import sync_playwright
import time



def crawl_post_comments(post_url, sleep=1):
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False, slow_mo=500)
        page = browser.new_page()
        page.on("response", lambda resp: print(resp.status, resp.url))
        
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
        
        browser.close()
        time.sleep(sleep)
        return comments



def crawl_subreddit(subreddit_name, num_pages=3, sleep=1):
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False, slow_mo=500)
        page = browser.new_page()
        page.on("response", lambda resp: print(resp.status, resp.url))
        
        page.goto(f"https://old.reddit.com/r/{subreddit_name}")
        
        posts = []
        for page_num in range(num_pages):
            page.wait_for_selector('.thing')
            
            for post in page.query_selector_all('.thing'):
                comments = post.query_selector('.comments')
                if comments and 'comment' in comments.text_content().lower():
                    link = comments.get_attribute('href')
                    title = post.query_selector('.title a')
                    score_elem = post.query_selector('.score.unvoted')

                    if link and title:
                        posts.append({
                            'title': title.text_content(),
                            'link': f"https://old.reddit.com{link}" if link.startswith('/') else link,
                            'score': score_elem and (score_elem.get_attribute('title') or score_elem.text_content() or 0)
                        })
                        print(f"{title.text_content()}\n{link}\n")
            
            next_button = page.query_selector('.next-button a')
            if not next_button:
                break
            next_button.click()
        
        browser.close()
        time.sleep(sleep)
        return posts



def run():
    subreddit = input("Subreddit: ").strip() or "python"
    posts = crawl_subreddit(subreddit, num_pages=1)

    for p in posts:
        comments = crawl_post_comments(p["link"])
        for c in comments:
            time.sleep(1)
            print(f"{c['author']}: ({p['score']}) \n{c['content']})")

run()
