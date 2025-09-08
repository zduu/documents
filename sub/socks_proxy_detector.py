import requests
import socket
import struct
import time
from urllib.parse import urlparse

def fetch_socks_proxies(url=None, file_path=None, retries=3):
    """
    从给定URL或本地文件获取SOCKS代理列表
    
    Args:
        url (str): 代理列表的URL地址
        file_path (str): 本地代理列表文件路径
        retries (int): 重试次数
        
    Returns:
        list: 代理地址列表
    """
    # 如果提供了文件路径，从文件读取
    if file_path and file_path.endswith('.txt'):
        try:
            print(f"正在从本地文件读取代理列表: {file_path}")
            with open(file_path, 'r', encoding='utf-8') as f:
                proxies = []
                for line in f:
                    line = line.strip()
                    if line:
                        proxies.append(line)
                print(f"成功从文件读取到 {len(proxies)} 个代理")
                return proxies
        except Exception as e:
            print(f"从文件读取代理时出错: {e}")
            return []
    
    # 否则从URL获取
    if url:
        for attempt in range(retries):
            try:
                print(f"正在获取代理列表... (尝试 {attempt + 1}/{retries})")
                headers = {
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
                }
                response = requests.get(url, timeout=15, headers=headers)
                response.raise_for_status()
                proxies = []
                for line in response.text.strip().split('\n'):
                    if line.strip():
                        proxies.append(line.strip())
                print(f"成功获取到 {len(proxies)} 个代理")
                return proxies
            except Exception as e:
                print(f"获取代理时出错: {e}")
                if attempt < retries - 1:
                    print(f"等待2秒后重试...")
                    time.sleep(2)
                else:
                    print("已达到最大重试次数")
    return []

def validate_socks_proxy(proxy, timeout=5):
    """
    通过尝试连接来验证SOCKS代理是否有效
    
    Args:
        proxy (str): 代理地址 (格式: host:port)
        timeout (int): 连接超时时间（秒）
        
    Returns:
        tuple: (是否有效, 响应时间)
    """
    try:
        # 解析代理地址
        if '://' in proxy:
            proxy = proxy.split('://', 1)[1]
        
        host, port = proxy.split(':')
        port = int(port)
        
        # 创建socket并设置超时
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        
        # 连接代理服务器
        start_time = time.time()
        sock.connect((host, port))
        connect_time = time.time() - start_time
        
        # 发送SOCKS5握手请求
        # SOCKS5版本标识符(5)和认证方法数量(1)
        sock.send(struct.pack('BB', 5, 1))
        # 认证方法(0 = 无认证)
        sock.send(struct.pack('B', 0))
        
        # 接收服务器响应
        response = sock.recv(2)
        sock.close()
        
        # 检查SOCKS5握手是否成功
        if len(response) == 2 and response[0] == 5:
            return True, connect_time
        else:
            return False, None
    except Exception as e:
        return False, None

def detect_socks_proxies(url):
    """
    检测和验证SOCKS代理的主函数
    
    Args:
        url (str): 包含代理列表的URL
    """
    print(f"正在从以下位置获取代理: {url}")
    proxies = fetch_socks_proxies(url)
    detect_socks_proxies_from_list(proxies)

def detect_socks_proxies_from_list(proxies):
    """
    从代理列表检测和验证SOCKS代理
    
    Args:
        proxies (list): 代理地址列表
    """
    if not proxies:
        print("未找到代理")
        return
    
    print(f"找到 {len(proxies)} 个代理。正在测试...")
    valid_proxies = []
    
    for i, proxy in enumerate(proxies):
        print(f"[{i+1}/{len(proxies)}] 正在测试 {proxy}...", end=" ")
        is_valid, response_time = validate_socks_proxy(proxy)
        
        if is_valid:
            print(f"有效 (响应时间: {response_time:.2f}秒)")
            valid_proxies.append((proxy, response_time))
        else:
            print("无效")
    
    # 按响应时间排序有效代理
    valid_proxies.sort(key=lambda x: x[1])
    
    print(f"\n找到 {len(valid_proxies)} 个有效的SOCKS代理:")
    for proxy, response_time in valid_proxies:
        print(f"  {proxy} ({response_time:.2f}秒)")
    
    # 将有效代理保存到文件
    if valid_proxies:
        save_valid_proxies(valid_proxies)
    
    return valid_proxies

def save_valid_proxies(valid_proxies):
    """
    将有效代理保存到文件
    
    Args:
        valid_proxies (list): 有效代理列表 [(proxy, response_time), ...]
    """
    try:
        with open('valid_socks_proxies.txt', 'w', encoding='utf-8') as f:
            f.write("# 有效的SOCKS代理列表\n")
            f.write("# 格式: IP:端口 响应时间(秒)\n")
            f.write("# 生成时间: {}\n\n".format(time.strftime("%Y-%m-%d %H:%M:%S")))
            
            for proxy, response_time in valid_proxies:
                f.write(f"{proxy} {response_time:.2f}\n")
        
        print(f"\n有效代理已保存到 'valid_socks_proxies.txt' 文件中")
        print(f"共保存 {len(valid_proxies)} 个有效代理")
    except Exception as e:
        print(f"保存有效代理列表时出错: {e}")

if __name__ == "__main__":
    # 优先从本地文件读取代理列表，如果文件不存在则从URL获取
    import os
    local_file = "socks5_proxies.txt"
    
    if os.path.exists(local_file):
        print("检测到本地代理列表文件，将从文件读取代理...")
        proxies = fetch_socks_proxies(file_path=local_file)
    else:
        print("未找到本地代理列表文件，将从URL获取...")
        socks_url = "https://socks5-proxy.pages.dev/socks5.txt"
        proxies = fetch_socks_proxies(url=socks_url)
    
    if proxies:
        detect_socks_proxies_from_list(proxies)
    else:
        print("未能获取代理列表")