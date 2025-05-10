from faker.providers import BaseProvider
from faker import Faker
import random
import faker

class products(BaseProvider):
    def prod_name(self) -> str:
        prod_lst=[
    "Wheat", "Corn", "Barley", "Soybean", "Rice", 
    "Cotton", "Sugarcane", "Coffee Beans", "Tea Leaves", 
    "Cocoa Beans", "Sunflower Seeds", "Potatoes", 
    "Tomatoes", "Apples", "Grapes",
    "Rapeseed Oil", "Cotton Yarn", "Refined Sugar", 
    "Silk Fabric", "Olive Oil", "Palm Oil", "Cane Sugar",
    "Beef Jerky", "Fruit Jam", "Honey",
    "Leather", "Paper", "Soap", 
    "Ceramic Tableware", "Plastic Products"
    ]
        return self.random_element(prod_lst)
    
    def price(self) -> float:
        return round(random.uniform(a=1.0,b=5.0),2)
    
    def status(self) -> str:
        return self.random_element(['active','inactive'])
    
    def created_by(self,cargo_id: list ) -> str:
        return self.random_element(cargo_id)
    
    def describe(self,prod_name_: str ,price_: float,status_: str) -> str:
        desc=' '.join(['this is',prod_name_,',it\'s',price_,'yuan per 500g',',it\'s',status_])
        return desc
    
product=Faker()
product.add_provider(products)

if __name__ == '__main__':
    print(product.status())