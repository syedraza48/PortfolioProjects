/*

Cleaning Data in SQL Queries

*/

SELECT *
FROM Data_Cleansing.dbo.NashvilleHousing

----------------------------------------------------------------------------

--Standardize Date Format


SELECT SaleDate2, CONVERT(Date,SaleDate)
FROM Data_Cleansing.dbo.NashvilleHousing

UPDATE Data_Cleansing.dbo.NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)

ALTER TABLE Data_Cleansing.dbo.NashvilleHousing
Add SaleDate2 Date;

UPDATE Data_Cleansing.dbo.NashvilleHousing
SET SaleDate2 = CONVERT(DATE,SaleDate)

-------------------------------------------------------------------------------------

--Populate Property Address Data

SELECT *
FROM Data_Cleansing.dbo.NashvilleHousing
--WHERE PropertyAddress is null
ORDER BY ParcelID

/*When property address is null but parcel ID is the same, and there exists another row with an address and the same parcel ID
 then replace null fields with property address for the other row that has same Parcel ID */

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Data_Cleansing.dbo.NashvilleHousing a
JOIN Data_Cleansing.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID]
WHERE a.PropertyAddress is null


UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Data_Cleansing.dbo.NashvilleHousing a
JOIN Data_Cleansing.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID]
WHERE a.PropertyAddress is null

--------------------------------------------------------------------------------------

--Breaking out Address into Individual Columns (Address, City, State)


SELECT PropertyAddress
FROM Data_Cleansing.dbo.NashvilleHousing
--WHERE PropertyAddress is null
--ORDER BY ParcelID

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as Address
FROM Data_Cleansing.dbo.NashvilleHousing


ALTER TABLE Data_Cleansing.dbo.NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

UPDATE Data_Cleansing.dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) 

ALTER TABLE Data_Cleansing.dbo.NashvilleHousing
Add PropertySplitCity Nvarchar(255);

UPDATE Data_Cleansing.dbo.NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

/* Now that we have split the address and city, it's much more usable */



SELECT OwnerAddress
FROM Data_Cleansing.dbo.NashvilleHousing

/* will split address again using Parse Name instead of substring. Much mor useful for delimited data. */


SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
FROM Data_Cleansing.dbo.NashvilleHousing


ALTER TABLE Data_Cleansing.dbo.NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

UPDATE Data_Cleansing.dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)

ALTER TABLE Data_Cleansing.dbo.NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

UPDATE Data_Cleansing.dbo.NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)



ALTER TABLE Data_Cleansing.dbo.NashvilleHousing
Add PropertySplitState Nvarchar(255);

UPDATE Data_Cleansing.dbo.NashvilleHousing
SET PropertySplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)


SELECT *
FROM Data_Cleansing.dbo.NashvilleHousing

/*Now we have data split from dilimiter, in separate columns, and easier to use */

----------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT(SoldAsVacant), Count(SoldAsVacant)
FROM Data_Cleansing.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

--^^ Number of Y, N, Yes, No.  Will use CASE statement to make changes

SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'N' THEN 'No'
		 WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 ELSE SoldAsVacant
		 END
FROM Data_Cleansing.dbo.NashvilleHousing


UPDATE Data_Cleansing.dbo.NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'N' THEN 'No'
						WHEN SoldAsVacant = 'Y' THEN 'Yes'
						ELSE SoldAsVacant
						END

----------------------------------------------------------------------------------------------------

--Remove Duplicates

/* Identify duplicates using Row Number and Delete */

WITH RowNumCTE AS(
SELECT *, 
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY UniqueID
					) row_num
FROM Data_Cleansing.dbo.NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1


/* Now check for duplicates after deleting */


WITH RowNumCTE AS(
SELECT *, 
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY UniqueID
					) row_num
FROM Data_Cleansing.dbo.NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1

-- No duplicates returned

----------------------------------------------------------------------------------------------------

--Delete Unused Columns


SELECT *
FROM Data_Cleansing.dbo.NashvilleHousing

ALTER TABLE Data_Cleansing.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress


ALTER TABLE Data_Cleansing.dbo.NashvilleHousing
DROP COLUMN SaleDate
