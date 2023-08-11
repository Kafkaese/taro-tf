from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.action_chains import ActionChains
import time
import os


# Configure Firefox options for headless mode
firefox_options = webdriver.FirefoxOptions()
firefox_options.add_argument('--headless')

# Path for logs
log_path = os.environ['LOG_PATH'] + '/geckodriver.log'

# App url
url = f"{os.environ['REACT_HOST']}:{os.environ['REACT_PORT']}"

def test_sidebar():
    
    # Open app
    driver = webdriver.Firefox(options=firefox_options)
     # Replace with the desired website URL
    driver.get(url)

    # Wait for app to load
    time.sleep(1)
    
    # Switch to export map
    try:
        toggle = driver.find_element(By.CLASS_NAME, 'toggle')
        export_button = toggle.find_element(By.CLASS_NAME, 'text-box')
        export_button.click()
    except Exception as e:
        print(f"Error: {e}")
    
    # Click on France
    try:
        geography = driver.find_elements(By.CLASS_NAME, 'rsm-geography')[56]
        geography.click()
    except Exception as e:
        print(f"Error: {e}")
        
    # Find sidebar elements
    try:
        sidebar  = driver.find_element(By.CLASS_NAME, 'sideBar')
        title = sidebar.find_element(By.CLASS_NAME, 'title')
    except Exception as e:
        print(f"Error: {e}")
        
    # Sleep for headless
    time.sleep(1)
    
    print(title.text)
    # Check values
    assert title.text == 'France'
    
    # End driver session
    driver.quit()
    
if __name__ == '__main__':
    test_sidebar()