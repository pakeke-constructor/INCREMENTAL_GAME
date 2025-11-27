
import requests
import time

def scrape_top_posts(subreddit, limit=100, sleep=1):
    posts = []
    after = None
    
    while len(posts) < limit:
        time.sleep(sleep)
        url = f"https://www.reddit.com/r/{subreddit}/top.json"
        params = {'limit': min(100, limit - len(posts)), 't': 'all'}
        if after:
            params['after'] = after
        
        response = requests.get(url, params=params, headers={'User-Agent': 'Scraper'})
        data = response.json()
        
        children = data['data']['children']
        if not children:
            break
        
        for child in children:
            p = child['data']
            posts.append({
                'title': p['title'],
                'upvotes': p['ups'],
                'url': p['url'],
                'permalink': f"https://www.reddit.com{p['permalink']}"
            })
        
        after = data['data']['after']
        if not after:
            break
    
    return posts


def get_comments(url, sleep=1):
    r = requests.get(url, headers={'User-Agent': 'script'})
    data = r.json()
    comments = []
    
    def extract(items):
        for item in items:
            if item['kind'] == 't1':
                c = item['data']
                comments.append({'author': c['author'], 'body': c['body']})
                if c.get('replies'):
                    extract(c['replies']['data']['children'])
    
    extract(data[1]['data']['children'])
    return comments




def scrape_incremental_sentiment():
    subreddit = "incremental_games"
    posts = scrape_top_posts(subreddit, limit=10)

    time.sleep(1)

    for i, post in enumerate(posts[:10], 1):
        upvotes = post["upvotes"]
        title = post["title"]
        url = post["url"]

        all_comments = get_comments(url + ".json", sleep=2)
        for c in all_comments:
            print(f"{c['author']}: {c['body']}\n")

        print("COMMENTS DONE DONE!")



scrape_incremental_sentiment()
