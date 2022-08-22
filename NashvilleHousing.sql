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