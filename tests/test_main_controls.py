from selenium import webdriver
from selenium.webdriver.common.by import By
import time

def test_zoom_in():
    # Open app
    driver = webdriver.Firefox()
    url = 'localhost:3000'  # Replace with the desired website URL
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
    except Exception as e:
        print(f"Error: {e}")
    
    # Check zoom level
    assert zoom_level == "translate(-80 -60) scale(1.2)"

    # Close driver
    driver.quit()
    
if __name__ == "__main__":
    test_zoom_in()
