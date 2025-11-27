
import requests
import time

def scrape_top_posts(subreddit, limit=100, time_sleep=1):
    posts = []
    after = None
    
    while len(posts) < limit:
        time.sleep(time_sleep)
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



def get_comments(url, time_sleep=1):
    time.sleep(time_sleep)

    r = requests.get(
        url,
        headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'},
        params={'raw_json':1}
    )

    print(r)

    data = r.json()
    print("DATA:",data)
    print("\n\n")
    comments = []
    
    def extract(items):
        for item in items:
            if item['kind'] == 't1':
                c = item['data']
                print("KEYS",c.keys())
                return
                comments.append({'author': c['author'], 'body': c['body']})
                if c.get('replies'):
                    extract(c['replies']['data']['children'])
    
    extract(data[1]['data']['children'])
    return comments





def scrape_incremental_sentiment():
    subreddit = "incremental_games"
    posts = scrape_top_posts(subreddit, limit=10)

    for i, post in enumerate(posts[:10], 1):
        upvotes = post["upvotes"]
        title = post["title"]
        url = post["url"]

        all_comments = get_comments(url)
        for c in all_comments:
            print(f"{c['author']}: {c['body']}\n")



scrape_incremental_sentiment()
