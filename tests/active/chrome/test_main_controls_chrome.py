from selenium import webdriver
from selenium.webdriver.common.by import By
import time
import os

# Configure Chrome options for headless mode
chrome_options = webdriver.ChromeOptions()
chrome_options.add_argument('--headless')

# Path for logs
log_path = os.environ['LOG_PATH'] + '/geckodriver.log'

# App url
url = f"{os.environ['REACT_HOST']}:{os.environ['REACT_PORT']}"

def test_zoom_in():
    '''
    Tests zoom in button working correctly
    '''
    
    # Open app
    driver = webdriver.Chrome(options=chrome_options)
     # Replace with the desired website URL
    driver.get(url)

    # Wait for app to load
    time.sleep(1)
    
    # Click zoom in button
    try:
        zoom_element = driver.find_element(By.CLASS_NAME, 'zoom')
        zoom_in = zoom_element.find_element(By.TAG_NAME, 'button')
        zoom_in.click()
    except Exception as e:
        print(f"Error: {e}")

    # Get zoom level
    try:
        zoomable_group = driver.find_element(By.CLASS_NAME, 'rsm-zoomable-group')
        zoom_level = zoomable_group.get_attribute('transform')
        
        # Check zoom level
        assert zoom_level == "translate(-80 -60) scale(1.2)"
        
    except Exception as e:
        print(f"Error: {e}")
    
    

    # Close driver
    driver.quit()

def test_zoom_out():
    '''
    Tests zoom out button working correctly
    '''
    
    # Open app
    driver = webdriver.Chrome(options=chrome_options)
     # Replace with the desired website URL
    driver.get(url)

    # Wait for app to load
    time.sleep(1)
    
    # Click zoom in button
    try:
        zoom_element = driver.find_element(By.CLASS_NAME, 'zoom')
        zoom_out = zoom_element.find_elements(By.TAG_NAME, 'button')[1]
        zoom_out.click()
    except Exception as e:
        print(f"Error: {e}")

    # Get zoom level
    try:
        zoomable_group = driver.find_element(By.CLASS_NAME, 'rsm-zoomable-group')
        zoom_level = zoomable_group.get_attribute('transform')
        
        # Check zoom level
        assert zoom_level == "translate(66.66666666666663 50) scale(0.8333333333333334)"
    
    except Exception as e:
        print(f"Error: {e}")

    # Close driver
    driver.quit()
    
if __name__ == "__main__":
    test_zoom_in()
