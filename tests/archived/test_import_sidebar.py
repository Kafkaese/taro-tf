from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time
import os


# Configure Firefox options for headless mode
firefox_options = webdriver.ChromeOptions()
firefox_options.add_argument('--headless')

# Path for logs
log_path = os.environ['LOG_PATH'] + '/geckodriver.log'

# App url
url = f"http://{os.environ['REACT_HOST']}:{os.environ['REACT_PORT']}"

def test_sidebar():
    
    # Open app
    driver = webdriver.Chrome(options=firefox_options)
    
    # Get app
    print(url)
    driver.get(url)

    # Wait for app to load
    time.sleep(10)
    
    # Click on Afghanistan
    try:
        geography = driver.find_element(By.CLASS_NAME, 'rsm-geography')
        geography.click()
    except Exception as e:
        print(f"Error: {e}")
        
    # Sleep for headless
    wait = WebDriverWait(driver, 10)
    sidebar = wait.until(EC.visibility_of_element_located((By.CLASS_NAME, 'sideBar')))

    
    # Find sidebar elements
    try:
        #sidebar  = driver.find_element(By.CLASS_NAME, 'sideBar')
        title = sidebar.find_element(By.CLASS_NAME, 'title')
    except Exception as e:
        print(f"Error: {e}")
    
    print(title)
    print(title.tag_name)
    print(title.text)
    # Check values
    assert title.text == 'Afghanistan'
    
    # Quit driver
    driver.quit()
    
if __name__ == '__main__':
    test_sidebar()