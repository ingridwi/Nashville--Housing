SELECT * 
FROM [dbo].[NashvilleHousingData]

-- Remove "" in column that appearead during data import 

UPDATE [dbo].[NashvilleHousingData]
SET SaleDate = SUBSTRING(SaleDate, 2, LEN(SaleDate)-2),
    PropertyAddress = SUBSTRING(PropertyAddress, 2, LEN(PropertyAddress)-2),
    OwnerName = SUBSTRING(OwnerName, 2, LEN(OwnerName)-2),
    OwnerAddress = SUBSTRING(OwnerAddress, 2, LEN(OwnerAddress)-2);

-- Standardize Date Format

UPDATE [dbo].[NashvilleHousingData]
SET SaleDate = SUBSTRING(SaleDate, 2, LEN(SaleDate)-2);

UPDATE [dbo].[NashvilleHousingData]
SET SaleDate = TRY_PARSE(SaleDate AS Date);

-- Standardize SalePrice field
UPDATE [dbo].[NashvilleHousingData]
SET SalePrice = SUBSTRING(SalePrice, 2, LEN(SalePrice)-2)
WHERE SalePrice LIKE '"%';

UPDATE [dbo].[NashvilleHousingData]
SET  SalePrice = REPLACE(REPLACE(SalePrice, ',', ''), '$', '')
WHERE SalePrice LIKE '$%';

UPDATE [dbo].[NashvilleHousingData]
SET  SalePrice = TRY_CAST(SalePrice AS NUMERIC)

-- Populate Property Address Data using ParcelID
-- because certain rows have same parcelID but NULL property address

UPDATE a 
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM [dbo].[NashvilleHousingData] a
JOIN [dbo].[NashvilleHousingData] b 
    ON a.ParcelID = b.ParcelID 
    AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

-- Breaking out Address into Individual Columns (Address, City, State)

ALTER TABLE [dbo].[NashvilleHousingData]
ADD OwnerSplitAddress Nvarchar(255),
    OwnerSplitCity Nvarchar(255),
    OwnerSplitState Nvarchar(255);

UPDATE [dbo].[NashvilleHousingData]
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
    OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
    OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

-- Change Y and N to Yes and No in "Sold as Vacant" field 

UPDATE [dbo].[NashvilleHousingData]
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
         WHEN SoldAsVacant = 'N' THEN 'No'
         ELSE SoldAsVacant
         END
FROM [dbo].[NashvilleHousingData];

Select DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM [dbo].[NashvilleHousingData]
GROUP BY SoldAsVacant;

-- Remove Duplicates 

WITH RowNumCTE AS(
SELECT *, 
    ROW_NUMBER() OVER (
        PARTITION BY ParcelID, 
                     PropertyAddress, 
                     SalePrice, 
                     SaleDate, 
                     LegalReference
                     ORDER BY UniqueID) row_num
FROM [dbo].[NashvilleHousingData]
)
DELETE 
FROM RowNumCTE
WHERE row_num > 1

-- Create new column to categorise bedrooms and fullbaths

ALTER TABLE [dbo].[NashvilleHousingData]
ADD bedroomscategory Nvarchar(255),
    fullbathcategory Nvarchar(255);

UPDATE [dbo].[NashvilleHousingData]
SET bedroomscategory =  
    CASE WHEN bedrooms < 2 THEN '< 2'
         WHEN bedrooms > 4 THEN '> 4'
    ELSE CAST(bedrooms AS NVARCHAR(2))
    END,
    fullbathcategory =  
    CASE WHEN fullbath > 3 THEN '> 3'
    ELSE CAST(fullbath AS NVARCHAR(2))
    END
FROM [dbo].[NashvilleHousingData];
