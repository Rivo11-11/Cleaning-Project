/*
Cleaning Data in sql 
Notice you must keep an orginal copy of your raw data
to try to get the data back if any operation in cleaning got wrong or missed up 
*/
SELECT * FROM [Portofolio Project]..NashvilleHoussing
order by [UniqueID ]
--------------------------------------------------------
-- standarise Date Format
/*
Convert from datetime to date
*/
ALTER TABLE NashvilleHoussing
Add SaleDateConverted Date ;

UPDATE NashvilleHoussing 
SET SaleDateConverted = CONVERT(Date, SaleDate)

SELECT SaleDate,SaleDateConverted  from [Portofolio Project]..NashvilleHoussing



-----------------------------------------------


-- Populate property Address Data
/*
From the parse id we will try to fill the null values ..
some parse_id have values 
some null have the same parse_id
mapping or copying the values then from the 2

*/
SELECT * from NashvilleHoussing 
where PropertyAddress is null

SELECT n1.ParcelID,n1.PropertyAddress,n2.ParcelID,n2.PropertyAddress from [Portofolio Project]..NashvilleHoussing as n1 
JOIN [Portofolio Project]..NashvilleHoussing as n2 ON n1.ParcelID = n2.ParcelID 
WHERE n1.PropertyAddress is NULL and n2.PropertyAddress is NOT NULL


UPDATE  n1
SET PropertyAddress = ISNULL(n1.propertyAddress,n2.PropertyAddress)
from [Portofolio Project]..NashvilleHoussing as n1 
JOIN [Portofolio Project]..NashvilleHoussing as n2 ON n1.ParcelID = n2.ParcelID 
WHERE n1.PropertyAddress is NULL and n2.PropertyAddress is NOT NULL

---------------------------------------------------


-- Breaking out address into individual columns (Address,city,State)

/*
only one comma exist a separator between city and state
*/
SELECT PropertyAddress FROM NashvilleHoussing

-- We eliminated the city after the comma 
SELECT SUBSTRING(PropertyAddress,1,CHARINDEX(',',propertyAddress)-1) as address ,
SUBSTRING(PropertyAddress,CHARINDEX(',',propertyAddress)+1,LEN(propertyAddress)) as city
 FROM NashvilleHoussing
 
ALTER TABLE NashvilleHoussing
Add PropertyAddressSplitAddress Nvarchar(255);
ALTER TABLE NashvilleHoussing
Add PropertyAddressSplitCity Nvarchar(255);

UPDATE NashvilleHoussing 
set PropertyAddressSplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',',propertyAddress)+1,LEN(propertyAddress))

UPDATE NashvilleHoussing 
set PropertyAddressSplitAddress =SUBSTRING(PropertyAddress,1,CHARINDEX(',',propertyAddress)-1)

SELECT PropertyAddress,PropertyAddressSplitAddress,PropertyAddressSplitCity FROM NashvilleHoussing


-------- Handling Owner_Address => address,city,state

SELECT OwnerAddress FROM NashvilleHoussing

-- Replace will replace each ',' to '.
-- Parse name parse the name backword from 1 it collect a word until it finds a '.'
-- That's why we replaced
SELECT owneraddress ,
PARSENAME(REPLACE(OwnerAddress,',','.'),3),
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
  FROM NashvilleHoussing
where OwnerAddress is not null

ALTER TABLE NashvilleHoussing
Add OwnerAddressSplitAddress Nvarchar(255);
ALTER TABLE NashvilleHoussing
Add OwnerAddressSplitCity Nvarchar(255);
ALTER TABLE NashvilleHoussing
Add OwnerAddressSplitState Nvarchar(255);

UPDATE NashvilleHoussing 
set OwnerAddressSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)
UPDATE NashvilleHoussing 
set OwnerAddressSplitAddress =PARSENAME(REPLACE(OwnerAddress,',','.'),3)
UPDATE NashvilleHoussing 
set OwnerAddressSplitState =PARSENAME(REPLACE(OwnerAddress,',','.'),1)




--------------------------------

-- change Y , N to yes,no in "Sold as vacant" field

SELECT DISTINCT(SoldAsVacant),count(SoldAsVacant) FROM NashvilleHoussing
group by SoldAsVacant
order by 2

SELECT SoldAsVacant , CASE
WHEN SoldAsVacant = 'Y' THEN 'Yes'
WHEN SoldAsVacant = 'N' THEN 'No'
ELSE SoldAsVacant
END
from NashvilleHoussing

UPDATE NashvilleHoussing 
SET SoldAsVacant = CASE
WHEN SoldAsVacant = 'Y' THEN 'Yes'
WHEN SoldAsVacant = 'N' THEN 'No'
ELSE SoldAsVacant
END
--------------------------------------
--Remove Duplicate 

-- identify Duplicate , using Row number over partition on unique attribute
-- they duplicate if they have same saleprice,saledate.propertyaddress,legalreference,ParselID
WITH RowNumCTE
 AS 
(
SELECT *, ROW_NUMBER()
OVER(
Partition by ParcelID,
propertyAddress,
SalePrice,
SaleDate, 
LegalReference
ORDER BY UniqueID
) as row_num FROM NashvilleHoussing
)

SELECT * FROM RowNumCTE
WHERE row_num > 1

DELETE  FROM RowNumCTE
WHERE row_num > 1




---------------------------------------

-- Deleting unused Columns
--DELETE Owner Address , Property Address because we parse them into 3,2 columns
--Also TaxDistrict
SELECT * FROM NashvilleHoussing


ALTER TABLE NashvilleHoussing
DROP COLUMN OwnerAddress,TaxDistrict,PropertyAddress



-------------------------------