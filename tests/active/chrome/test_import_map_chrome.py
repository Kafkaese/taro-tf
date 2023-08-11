from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time
import os


# Configure Chrome options for headless mode
chrome_options = webdriver.ChromeOptions()
chrome_options.add_argument('--headless')

# Path for logs
log_path = os.environ['LOG_PATH'] + '/geckodriver.log'

# App url
url = f"{os.environ['REACT_HOST']}:{os.environ['REACT_PORT']}"

def test_hover_toolip():
    
    # Open app
    driver = webdriver.Chrome(options=chrome_options)
     # Replace with the desired website URL
    driver.get(url)

    # Wait for app to load
    time.sleep(1)
    
    # Hover over Afhganistan
    try:
        geography = driver.find_element(By.CLASS_NAME, 'rsm-geography')
        actions = ActionChains(driver)
        actions.move_to_element(geography).perform()  
    except Exception as e:
        print(f"Error: {e}")
        
    # Find hover box container
    try:  
       
        wait = WebDriverWait(driver, 10)
        container = wait.until(EC.visibility_of_element_located((By.CLASS_NAME, 'hover-box-container')))
        assert container != None   
    except Exception as e:
        print(f"Error: {e}")
        
    # Quit driver 
    driver.quit()
    
def test_hover_toolip_data():
    
    # Open app
    driver = webdriver.Chrome(options=chrome_options)
     # Replace with the desired website URL
    driver.get(url)

    # Wait for app to load
    time.sleep(1)
    
    # Hover over random country
    try:
        geography = driver.find_element(By.CLASS_NAME, 'rsm-geography')
        actions = ActionChains(driver)
        actions.move_to_element(geography).perform()
    except Exception as e:
        print(f"Error: {e}")
        
    # Find hover box container
    time.sleep(1)
    try:
        wait = WebDriverWait(driver, 10)
        container = wait.until(EC.visibility_of_element_located((By.CLASS_NAME, 'hover-box-container')))
    
        # Check country name and data
        assert container.find_element(By.TAG_NAME, 'h3').text == "Afghanistan"
        assert container.find_element(By.CLASS_NAME, 'money').text != "no data"
        assert container.find_element(By.CLASS_NAME, 'money-label').text != ""
    
    except Exception as e:
        print(f"Error: {e}")
        
    # Quit driver
    driver.quit()
    
if __name__ == '__main__':
    test_hover_toolip_data()