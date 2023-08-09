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

def test_hover_toolip():
    
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

    
    # Hover over France
    try:
        geography = driver.find_elements(By.CLASS_NAME, 'rsm-geography')[56]
        actions = ActionChains(driver)
        actions.move_to_element(geography).perform()
    except Exception as e:
        print(f"Error: {e}")
        
    # Find hover box container
    time.sleep(1)
    container = driver.find_element(By.CLASS_NAME, 'hover-box-container')
    assert container != None
    
    # Check country name
    assert container.find_element(By.TAG_NAME, 'h3').text == "France"
    assert container.find_element(By.CLASS_NAME, 'money').text != "no data"
    assert container.find_element(By.CLASS_NAME, 'money-label').text != ""
    
    # quit webdriver
    driver.quit()
    
if __name__ == '__main__':
    test_hover_toolip()