{-# LANGUAGE OverloadedStrings , DeriveGeneric, DuplicateRecordFields , DeriveAnyClass , DeriveDataTypeable , TypeOperators  #-}

module Data.Morpheus.Types.Introspection
  ( GQL__Type(..)
  , GQL__Field(..)
  , GQL__TypeKind(..)
  , GQL__InputValue(..)
  , createType
  , createField
  , GQLTypeLib
  , emptyLib
  , GQL__EnumValue(..)
  , GQL__Deprecation__Args(..)
  , createInputValue
  , wrapListType
  , unwrapType
  , createScalar
  , createFieldWith
  , createEnum
  )
where

import           Data.Text                      ( Text(..)
                                                , pack
                                                )
import           Data.Map                       ( Map
                                                , fromList
                                                )
import           GHC.Generics
import           Data.Aeson
import           Data.Data                      ( Data )
import           Data.Morpheus.Types.Types      ( (::->)(..) , EnumOf(..) )
import           Data.Morpheus.Schema.GQL__TypeKind
                                                ( GQL__TypeKind(..) )
import           Data.Morpheus.Schema.GQL__EnumValue
                                                ( GQL__EnumValue , createEnumValue)
import           Data.Maybe                     ( fromMaybe )
data GQL__Type =  GQL__Type {
   kind :: EnumOf GQL__TypeKind
  ,name :: Text
  ,description :: Text
  ,fields :: GQL__Deprecation__Args ::-> [GQL__Field]
  ,ofType :: Maybe GQL__Type
  ,interfaces :: [GQL__Type]
  ,possibleTypes :: [GQL__Type]
  ,enumValues:: GQL__Deprecation__Args ::-> [GQL__EnumValue]
  ,inputFields:: [GQL__InputValue]
} deriving (Show , Data, Generic)

data GQL__Deprecation__Args = DeprecationArgs {
  includeDeprecated:: Maybe Bool
} deriving (Show , Data, Generic )

data GQL__Field = GQL__Field{
  name:: Text,
  description:: Text,
  args:: [GQL__InputValue],
  _type :: Maybe GQL__Type,
  isDeprecated:: Bool,
  deprecationReason :: Text
} deriving (Show , Data, Generic)

data GQL__InputValue  = GQL__InputValue {
  name:: Text,
  description::  Text,
  _type:: Maybe GQL__Type,
  defaultValue::  Text
} deriving (Show , Data, Generic)

createInputValue :: Text -> Text -> GQL__InputValue
createInputValue argname typeName = GQL__InputValue
  { name         = argname
  , description  = ""
  , _type        = Just $ createType typeName []
  , defaultValue = ""
  }

type GQLTypeLib = Map Text GQL__Type;

createField :: Text -> Text -> [GQL__InputValue] -> GQL__Field
createField argname typeName args = GQL__Field
  { name              = argname
  , description       = "my description"
  , args              = args
  , _type             = Just $ createType typeName []
  , isDeprecated      = False
  , deprecationReason = ""
  }

createFieldWith :: Text -> GQL__Type -> [GQL__InputValue] -> GQL__Field
createFieldWith argname fieldtype args = GQL__Field
  { name              = argname
  , description       = "my description"
  , args              = args
  , _type             = Just fieldtype
  , isDeprecated      = False
  , deprecationReason = ""
  }

createType :: Text -> [GQL__Field] -> GQL__Type
createType name fields = GQL__Type
  { kind          = EnumOf OBJECT
  , name          = name
  , description   = "my description"
  , fields        = Some fields
  , ofType        = Nothing
  , interfaces    = []
  , possibleTypes = []
  , enumValues    = Some []
  , inputFields   = []
  }

createScalar  :: Text -> GQL__Type
createScalar name  = GQL__Type {
  kind          = EnumOf SCALAR
  , name          = name
  , description   = "my description"
  , fields        = Some []
  , ofType        = Nothing
  , interfaces    = []
  , possibleTypes = []
  , enumValues    = Some []
  , inputFields   = []
}

createEnum  :: Text -> [Text] -> GQL__Type
createEnum name tags = GQL__Type {
  kind          = EnumOf ENUM
  , name          = name
  , description   = "my description"
  , fields        = Some []
  , ofType        = Nothing
  , interfaces    = []
  , possibleTypes = []
  , enumValues    = Some $ map createEnumValue tags
  , inputFields   = []
}


unwrapType :: GQL__Type -> Maybe GQL__Type
unwrapType x = case kind x of
  EnumOf LIST -> ofType x
  _    -> Just x

wrapListType :: GQL__Type -> GQL__Type
wrapListType contentType = GQL__Type
  { kind          = EnumOf LIST
  , name          = ""
  , description   = "list Type"
  , fields        = None
  , ofType        = Just contentType
  , interfaces    = []
  , possibleTypes = []
  , enumValues    = None
  , inputFields   = []
  }

emptyLib :: GQLTypeLib
emptyLib = fromList []