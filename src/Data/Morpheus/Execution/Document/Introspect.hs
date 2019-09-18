{-# LANGUAGE NamedFieldPuns    #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE TemplateHaskell   #-}

module Data.Morpheus.Execution.Document.Introspect
  ( deriveArguments
  , deriveIntrospect
  ) where

import           Data.Proxy                                (Proxy (..))
import           Data.Semigroup                            ((<>))
import           Language.Haskell.TH

--
-- MORPHEUS
import           Data.Morpheus.Execution.Server.Introspect (Introspect (..), ObjectFields (..), buildType, updateLib)
import           Data.Morpheus.Types.GQLType               (GQLType (__typeName))
import           Data.Morpheus.Types.Internal.Data         (DataField (..), DataFullType (..), DataTypeWrapper (..))
import           Data.Morpheus.Types.Internal.DataD        (AppD (..), ConsD (..), FieldD (..), TypeD (..))
import           Data.Morpheus.Types.Internal.TH           (instanceFunD, instanceHeadT)

-- [((Text, DataField), TypeUpdater)]
deriveArguments :: TypeD -> Q [Dec]
deriveArguments TypeD {tName, tCons = [ConsD {cFields}]} = pure <$> instanceD (cxt []) appHead methods
  where
    appHead = instanceHeadT ''ObjectFields tName []
    methods = [instanceFunD 'objectFields ["_"] body]
      where
        body = [|($(buildFields cFields), $(buildTypes cFields))|]
deriveArguments _ = pure []

deriveIntrospect :: TypeD -> Q [Dec]
deriveIntrospect TypeD {tName, tCons = [ConsD {cFields}]} = pure <$> instanceD (cxt []) appHead methods
  where
    appHead = instanceHeadT ''Introspect tName []
    methods = [instanceFunD 'introspect ["_"] body]
      where
        body = [|updateLib $(typeBuilder) $(types) (Proxy :: (Proxy $(typeName)))|]
        typeBuilder = [|InputObject . buildType $(buildFields cFields)|]
        types = buildTypes cFields
        typeName = conT $ mkName tName
deriveIntrospect _ = pure []

buildTypes :: [FieldD] -> ExpQ
buildTypes = listE . map introspectType
  where
    introspectType fieldD = [|introspect (Proxy :: Proxy $(lookupType fieldD))|]
      where
        lookupType FieldD {fieldTypeD} = conT $ mkName $ snd $ appDToField fieldTypeD

buildFields :: [FieldD] -> ExpQ
buildFields = listE . map buildField
  where
    buildField FieldD {fieldNameD, fieldTypeD} =
      [|( fieldNameD
        , DataField
            { fieldName = fieldNameD
            , fieldArgs = []
            , fieldTypeWrappers
            , fieldType = __typeName (Proxy :: (Proxy $(conT $ mkName fieldType)))
            , fieldHidden = False
            })|]
      where
        (fieldTypeWrappers, fieldType) = appDToField fieldTypeD

appDToField :: AppD String -> ([DataTypeWrapper], String)
appDToField = appDToField []
  where
    appDToField wrappers (MaybeD (ListD td))   = appDToField (wrappers <> [ListType]) td
    appDToField wrappers (ListD td)            = appDToField (wrappers <> [NonNullType, ListType]) td
    appDToField wrappers (MaybeD (MaybeD td))  = appDToField wrappers (MaybeD td)
    appDToField wrappers (MaybeD (BaseD name)) = (wrappers, name)
    appDToField wrappers (BaseD name)          = (wrappers <> [NonNullType], name)
